// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IComet} from "./IComet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

/**
 * @title DeFi Yield Aggregator
 * @author Obinna Franklin Duru
 * @notice Securely manages user funds to maximize yield across Aave and Compound protocols
 * @dev Implements deposit, withdraw fund, fee structure, emergency controls, and rebalancing logic.
 */
contract YieldAggregator is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Custom Errors
    error YieldAggregator__RefundFailed();
    error YieldAggregator__EmergencyExit();
    error YieldAggregator__InvalidETHAmount();
    error YieldAggregator__WETHApproveFailed();
    error YieldAggregator__InvalidConfiguration();
    error YieldAggregator__InvalidAddress(address addr);
    error YieldAggregator__DirectETHTransferNotAllowed();
    error YieldAggregator__RebalanceCooldown(uint256 timeRemaining);
    error YieldAggregator__FeeTooHigh(uint256 provided, uint256 maxAllowed);
    error YieldAggregator__InsufficientBalance(uint256 requested, uint256 available);

    // Protocol Structures
    enum ProtocolType {
        NONE,
        COMPOUND,
        AAVE
    }

    // User Deposit Tracking
    struct UserDeposit {
        uint256 amount; // Total deposited amount
        uint256 lastDepositTime; // Timestamp of last deposit
        uint256 accumulatedYield; // Accumulated yield for the user
    }

    struct Fees {
        uint96 annualManagementFeeInBasisPoints;
        uint96 performanceFee;
        uint64 lastRebalanceTimestamp;
    }

    // Immutable Configuration
    address public immutable WETH_ADDRESS;
    address public immutable AAVE_WETH_ADDRESS;
    address public immutable COMPOUND_PROXY_ADDRESS;
    address public immutable AAVE_POOL_PROVIDER;

    // Fee-related constants
    uint256 public constant BASIS_POINTS = 10000;
    uint96 public constant MAX_MANAGEMENT_FEE = 500; // 5%
    uint96 public constant MAX_PERFORMANCE_FEE = 3000; // 30%

    uint256 public constant REBALANCE_COOLDOWN = 1 days; // Time-related constants

    // Mappings for Tracking
    mapping(address => UserDeposit) public userDeposits;
    mapping(address => bool) public emergencyAdmins;

    // State Variables
    Fees public fees;
    uint256 public totalDeposits;

    ProtocolType public currentProtocol;
    address public feeCollector;
    bool public emergencyExitEnabled;

    // Protocol Interfaces
    IERC20 public immutable wethToken;
    IComet public immutable compoundComet;
    IPool private aavePool;

    event Deposit(address indexed user, uint256 amount, ProtocolType protocol, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, ProtocolType protocol, uint256 yield);
    event EmergencyWithdrawal(address indexed owner, uint256 amount, ProtocolType protocol);
    event Rebalance(ProtocolType fromProtocol, ProtocolType toProtocol, uint256 amount, uint256 timestamp);
    event ETHRefunded(address indexed recipient, uint256 amount);
    event FeesCollected(
        address indexed user, uint96 performanceFee, uint96 annualManagementFeeInBasisPoints, uint256 timestamp
    );
    event ProtocolConfigurationUpdated(
        address indexed admin, address newFeeCollector, uint256 newManagementFee, uint256 newPerformanceFee
    );

    // Events
    modifier onlyEmergencyAdmin() {
        if (!emergencyAdmins[msg.sender] && msg.sender != owner()) {
            revert YieldAggregator__InvalidAddress(msg.sender);
        }
        _;
    }

    modifier checkEmergency() {
        if (emergencyExitEnabled) {
            revert YieldAggregator__EmergencyExit();
        }
        _;
    }

    // Constructor with Validation
    constructor(
        address _wethAddress,
        address _aaveWethAddress,
        address _compoundProxy,
        address _aavePoolProvider,
        address _feeCollector
    ) Ownable(msg.sender) {
        // Address Validation
        if (
            _wethAddress == address(0) || _aaveWethAddress == address(0) || _compoundProxy == address(0)
                || _aavePoolProvider == address(0) || _feeCollector == address(0)
        ) {
            revert YieldAggregator__InvalidConfiguration();
        }

        WETH_ADDRESS = _wethAddress;
        AAVE_WETH_ADDRESS = _aaveWethAddress;
        COMPOUND_PROXY_ADDRESS = _compoundProxy;
        AAVE_POOL_PROVIDER = _aavePoolProvider;

        wethToken = IERC20(_wethAddress);
        compoundComet = IComet(_compoundProxy);
        feeCollector = _feeCollector;

        fees.annualManagementFeeInBasisPoints = 100; // 1%
        fees.performanceFee = 1000; // 10% performance fee
    }

    //=====================Main Contract Interaction Methods===================
    /**
     * @notice Deposit funds into the highest-yielding protocol
     * @param _amount Amount of WETH to deposit
     * @param _compAPY Current Compound APY
     * @param _aaveAPY Current Aave APY
     */
    function deposit(uint256 _amount, uint256 _compAPY, uint256 _aaveAPY)
        external
        nonReentrant
        whenNotPaused
        checkEmergency
    {
        // Validate Deposit
        if (_amount == 0) {
            revert YieldAggregator__InsufficientBalance(_amount, 0);
        }

        // Transfer Tokens Safely
        wethToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Protocol Selection
        ProtocolType targetProtocol = _selectOptimalProtocol(_compAPY, _aaveAPY);

        // Update User Deposit
        UserDeposit storage userDeposit = userDeposits[msg.sender];
        userDeposit.amount += _amount;
        userDeposit.lastDepositTime = block.timestamp;

        // Update Total Deposits
        totalDeposits += _amount;

        // Protocol-Specific Deposit
        _depositToProtocol(targetProtocol, _amount);

        emit Deposit(msg.sender, _amount, targetProtocol, block.timestamp);
    }

    /**
     * @notice Withdraws funds with complete yield and risk calculations
     * @return amount Total withdrawn amount including yield
     */
    function withdraw() external nonReentrant whenNotPaused returns (uint256) {
        UserDeposit storage _userDeposit = userDeposits[msg.sender];
        uint256 _depositAmount = _userDeposit.amount;
        uint256 _grossAmount = _calculateTotalValue(msg.sender);
        uint256 _yield = _grossAmount > _depositAmount ? _grossAmount - _depositAmount : 0;
        uint256 _feeAmount = _collectFees(_yield);
        uint256 _netAmount = _grossAmount - _feeAmount;

        // Reset the user values
        delete userDeposits[msg.sender];
        totalDeposits -= _depositAmount;

        _withdrawFromProtocol(currentProtocol, _grossAmount);
        wethToken.safeTransfer(msg.sender, _netAmount);

        emit Withdrawal(msg.sender, _netAmount, currentProtocol, _yield);
        return _netAmount;
    }

    //============================Admin functions===========================
    /**
     * @notice Rebalancing between protocols
     * @param _compAPY Current Compound APY
     * @param _aaveAPY Current Aave APY
     */
    function rebalance(uint256 _compAPY, uint256 _aaveAPY)
        external
        nonReentrant
        onlyEmergencyAdmin
        whenNotPaused
        checkEmergency
    {
        // Check cooldown period
        uint256 timeSinceLastRebalance = block.timestamp - fees.lastRebalanceTimestamp;
        if (timeSinceLastRebalance < REBALANCE_COOLDOWN) {
            revert YieldAggregator__RebalanceCooldown(REBALANCE_COOLDOWN - timeSinceLastRebalance);
        }

        ProtocolType _targetProtocol = _selectOptimalProtocol(_compAPY, _aaveAPY);
        if (_targetProtocol == currentProtocol) return;

        // Calculate total value before rebalance
        uint256 _totalValue = _calculateTotalProtocolValue();

        // Perform rebalance
        _withdrawFromProtocol(currentProtocol, _totalValue);
        _depositToProtocol(_targetProtocol, _totalValue);

        // Update state
        ProtocolType _previousProtocol = currentProtocol;
        currentProtocol = _targetProtocol;
        fees.lastRebalanceTimestamp = uint64(block.timestamp);

        emit Rebalance(_previousProtocol, _targetProtocol, _totalValue, block.timestamp);
    }

    /**
     * @notice Updates the fee structure and fee collector address.
     * @param _newFeeCollector The address to receive collected fees.
     * @param _newManagementFee The new management fee (annual, in basis points).
     * @param _newPerformanceFee The new performance fee (in basis points).
     */
    function updateProtocolConfiguration(address _newFeeCollector, uint96 _newManagementFee, uint96 _newPerformanceFee)
        external
        onlyOwner
    {
        // Validate fee collector address
        if (_newFeeCollector == address(0)) revert YieldAggregator__InvalidAddress(address(0));

        // Validate management fee
        if (_newManagementFee > MAX_MANAGEMENT_FEE) {
            revert YieldAggregator__FeeTooHigh(_newManagementFee, MAX_MANAGEMENT_FEE);
        }

        // Validate performance fee
        if (_newPerformanceFee > MAX_PERFORMANCE_FEE) {
            revert YieldAggregator__FeeTooHigh(_newPerformanceFee, MAX_PERFORMANCE_FEE);
        }

        // Update state variables
        feeCollector = _newFeeCollector;
        fees.annualManagementFeeInBasisPoints = _newManagementFee;
        fees.performanceFee = _newPerformanceFee;

        // Emit event after successful update
        emit ProtocolConfigurationUpdated(msg.sender, _newFeeCollector, _newManagementFee, _newPerformanceFee);
    }

    /**
     * @notice Emergency withdrawal
     */
    function emergencyWithdraw() external nonReentrant onlyEmergencyAdmin {
        if (totalDeposits == 0) {
            revert YieldAggregator__InsufficientBalance(0, totalDeposits);
        }

        uint256 _totalValue = _calculateTotalProtocolValue();
        _withdrawFromProtocol(currentProtocol, _totalValue);

        // Transfer to owner for safe keeping
        wethToken.safeTransfer(owner(), _totalValue);

        // Reset contract state
        totalDeposits = 0;
        currentProtocol = ProtocolType.NONE;
        emergencyExitEnabled = true;

        emit EmergencyWithdrawal(owner(), _totalValue, currentProtocol);
    }

    //==============Internal Protocol Interaction Methods========================
    /**
     * @notice Protocol Selection
     * @param _compAPY Compound Protocol APY
     * @param _aaveAPY Aave Protocol APY
     * @return Recommended Protocol
     */
    function _selectOptimalProtocol(uint256 _compAPY, uint256 _aaveAPY) internal view returns (ProtocolType) {
        if (_compAPY > _aaveAPY) {
            return ProtocolType.COMPOUND;
        } else if (_aaveAPY > _compAPY) {
            return ProtocolType.AAVE;
        }

        // Fallback to Current Protocol if No Better Option
        return currentProtocol;
    }

    function _depositToProtocol(ProtocolType _protocol, uint256 _amount) internal {
        if (_protocol == ProtocolType.COMPOUND) {
            if (!wethToken.approve(address(compoundComet), _amount)) revert YieldAggregator__WETHApproveFailed();
            compoundComet.supply(WETH_ADDRESS, _amount);
        } else if (_protocol == ProtocolType.AAVE) {
            aavePool = _getAavePool();
            if (!wethToken.approve(address(aavePool), _amount)) revert YieldAggregator__WETHApproveFailed();
            aavePool.supply(WETH_ADDRESS, _amount, address(this), 0);
        } else {
            revert YieldAggregator__InvalidConfiguration();
        }
    }

    function _withdrawFromProtocol(ProtocolType _protocol, uint256 _amount) internal {
        if (_amount > _calculateTotalProtocolValue()) {
            revert YieldAggregator__InsufficientBalance(_amount, _calculateTotalProtocolValue());
        }

        if (_protocol == ProtocolType.COMPOUND) {
            uint256 _balance = compoundComet.balanceOf(address(this));
            _amount = _amount > _balance ? _balance : _amount;
            compoundComet.withdraw(WETH_ADDRESS, _amount);
        } else if (_protocol == ProtocolType.AAVE) {
            aavePool = _getAavePool();
            if (!IERC20(AAVE_WETH_ADDRESS).approve(address(aavePool), _amount)) {
                revert YieldAggregator__WETHApproveFailed();
            }
            aavePool.withdraw(WETH_ADDRESS, _amount, address(this));
        } else {
            revert YieldAggregator__InvalidConfiguration();
        }
    }

    /**
     * @notice Calculate total value including yield for a user
     * @param _user Address of the user
     * @return Total value in WETH
     */
    function _calculateTotalValue(address _user) internal view returns (uint256) {
        UserDeposit storage _userDeposit = userDeposits[_user];
        if (_userDeposit.amount == 0) return 0;

        uint256 _totalDeposits = totalDeposits;
        if (_totalDeposits == 0) return 0;

        uint256 totalValue = _calculateTotalProtocolValue();
        return (_userDeposit.amount * totalValue) / _totalDeposits;
    }

    /**
     * @notice Calculate total protocol value and may not account for underlying token appreciation
     * @dev Calculates total protocol value assuming 1:1 exchange rate
     * @return Total value in WETH
     */
    function _calculateTotalProtocolValue() internal view returns (uint256) {
        if (currentProtocol == ProtocolType.COMPOUND) {
            return compoundComet.balanceOf(address(this));
        } else if (currentProtocol == ProtocolType.AAVE) {
            return IERC20(AAVE_WETH_ADDRESS).balanceOf(address(this));
        }
        return 0;
    }

    /**
     * @notice Calculate and collect fees
     * @param _yield Amount of yield to calculate fees from
     * @return Total fees collected
     */
    function _collectFees(uint256 _yield) internal returns (uint256) {
        if (_yield == 0) return 0;

        uint256 _performanceFeeAmount = (_yield * fees.performanceFee) / BASIS_POINTS;
        uint256 _managementFeeAmount = (_yield * fees.annualManagementFeeInBasisPoints) / BASIS_POINTS;
        uint256 _totalFees = _performanceFeeAmount + _managementFeeAmount;

        if (_totalFees > 0) {
            wethToken.safeTransfer(feeCollector, _totalFees);
        }

        emit FeesCollected(msg.sender, fees.performanceFee, fees.annualManagementFeeInBasisPoints, block.timestamp);
        return _totalFees;
    }

    //=======================View Functions==================================
    function _getAavePool() private view returns (IPool) {
        return IPool(IPoolAddressesProvider(AAVE_POOL_PROVIDER).getPool());
    }

    function getUserValue(address _user) external view returns (uint256 principal, uint256 yield) {
        uint256 _totalValue = _calculateTotalValue(_user);
        principal = userDeposits[_user].amount;
        yield = _totalValue > principal ? _totalValue - principal : 0;
    }

    function getCurrentProtocolInfo() external view returns (ProtocolType _protocol, uint256 _totalValue) {
        _protocol = currentProtocol;
        _totalValue = _calculateTotalProtocolValue();
    }

    //================Fallback Functions==================================
    /**
     * @notice Internal function to safely refund ETH
     * @param _recipient Address to receive the refund
     * @param _amount Amount of ETH to refund
     */
    function _refundETH(address _recipient, uint256 _amount) internal {
        // Ensure the recipient is a valid address
        if (_recipient == address(0)) revert YieldAggregator__InvalidAddress(address(0));

        // Attempt to send ETH back to the recipient
        (bool success,) = payable(_recipient).call{value: _amount}("");
        if (!success) revert YieldAggregator__RefundFailed();

        emit ETHRefunded(_recipient, _amount);
    }

    /**
     * @notice Withdraw accumulated ETH from failed operations
     * @dev Only owner can withdraw stuck ETH
     */
    function withdrawStuckETH() external onlyOwner {
        uint256 _balance = address(this).balance;
        if (_balance > 0) _refundETH(owner(), _balance);
    }

    receive() external payable {
        // Check if emergency exit is not enabled
        if (emergencyExitEnabled) revert YieldAggregator__EmergencyExit();

        // Ensure the amount is not zero
        if (msg.value == 0) revert YieldAggregator__InvalidETHAmount();

        _refundETH(msg.sender, msg.value);
    }

    /**
     * @notice Fallback function with strict security measures
     * @dev Reverts all direct calls with data to prevent unintended interactions
     */
    fallback() external payable {
        // Revert any direct calls with data
        revert YieldAggregator__DirectETHTransferNotAllowed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IComet} from "./IComet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

/**
 * @title DeFi Yield Aggregator
 * @author Obinna franklin Duru
 * @notice Manages user funds to maximize yield by allocating to the highest-yielding protocol among Aave and Compound.
 * @dev Implements a fee structure, emergency controls, and rebalancing logic.
 */
contract YieldAggregator is Ownable, ReentrancyGuard, Pausable {
    // Constants
    address public immutable AaveV3PoolAddressProvider;
    address public immutable WETH_Address;
    address public immutable CompoundV3ProxyAddress;
    address public immutable AaaveWETH_Address;

    // State variables
    address public locationOfFunds;
    uint256 public depositAmount;
    uint256 public lastRebalanceTimestamp;
    uint256 public rebalanceThreshold; // Minimum APY difference to trigger rebalance
    uint256 public constant REBALANCE_COOLDOWN = 1 days;
    uint256 public constant BASIS_POINTS = 10000;
    
    // Fee structure
    uint256 public performanceFee; // In basis points
    uint256 public managementFee; // Annual fee in basis points
    uint256 public lastManagementFeeCollection;
    address public feeCollector;

    // Protocol integration
    IERC20 immutable weth;
    IERC20 immutable aaveAweth;
    IComet immutable comet;
    IPool public aavePool;

    // Emergency controls
    bool public emergencyExit;
    mapping(address => bool) public emergencyAdmins;

    // Events
    event Deposit(address indexed owner, uint256 amount, address depositTo);
    event Withdraw(address indexed owner, uint256 amount, address withdrawFrom);
    event Rebalance(address indexed owner, uint256 amount, address depositTo, uint256 compAPY, uint256 aaveAPY);
    event EmergencyWithdraw(address indexed owner, uint256 amount, address withdrawFrom);
    event PerformanceFeeCollected(uint256 amount);
    event ManagementFeeCollected(uint256 amount);
    event RebalanceThresholdUpdated(uint256 newThreshold);
    event EmergencyAdminUpdated(address indexed admin, bool status);

    // Modifiers
    modifier onlyEmergencyAdmin() {
        require(emergencyAdmins[msg.sender] || owner() == msg.sender, "Not emergency admin");
        _;
    }

    modifier checkEmergency() {
        require(!emergencyExit, "Contract is in emergency exit mode");
        _;
    }

    modifier ensureRebalanceCooldown() {
        require(
            block.timestamp >= lastRebalanceTimestamp + REBALANCE_COOLDOWN,
            "Rebalance cooldown not met"
        );
        _;
    }

    // Constructor to initialize addresses and configure fee structures
    constructor(
        address _aaveProvider,
        address _weth,
        address _compound,
        address _aaveWeth,
        address _feeCollector
    ) Ownable(msg.sender) {
        AaveV3PoolAddressProvider = _aaveProvider;
        WETH_Address = _weth;
        CompoundV3ProxyAddress = _compound;
        AaaveWETH_Address = _aaveWeth;
        feeCollector = _feeCollector;

        weth = IERC20(WETH_Address);
        aaveAweth = IERC20(AaaveWETH_Address);
        comet = IComet(CompoundV3ProxyAddress);

        // Initialize fees
        performanceFee = 1000; // 10% performance fee
        managementFee = 100; // 1% annual management fee
        rebalanceThreshold = 50; // 0.5% minimum difference for rebalance
        lastManagementFeeCollection = block.timestamp;
    }

    /**
     * @notice Deposits funds and allocates to the highest yielding protocol
     * @param _amount Amount of WETH to deposit
     * @param _compAPY Current Compound APY
     * @param _aaveAPY Current Aave APY
     */
    function deposit(
        uint256 _amount,
        uint256 _compAPY,
        uint256 _aaveAPY
    ) external nonReentrant whenNotPaused checkEmergency {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Collect management fee if applicable
        _collectManagementFee();

        if (depositAmount > 0) {
            _rebalanceIfNeeded(_compAPY, _aaveAPY);
        }

        // Transfer WETH from user
        require(
            weth.transferFrom(msg.sender, address(this), _amount),
            "WETH transfer failed"
        );

        depositAmount += _amount;

        // Deposit to highest yielding protocol
        if (_compAPY > _aaveAPY) {
            _depositToCompound(_amount);
        } else {
            _depositToAave(_amount);
        }

        emit Deposit(msg.sender, _amount, locationOfFunds);
    }

    /**
     * @notice Withdraws all funds from the current protocol
     * @return Amount withdrawn
     */
    function withdraw() external nonReentrant onlyOwner returns (uint256) {
        require(depositAmount > 0, "No deposits to withdraw");
        
        // Collect fees before withdrawal
        _collectManagementFee();
        _collectPerformanceFee();

        uint256 amount;
        if (locationOfFunds == address(comet)) {
            amount = _withdrawFromCompound();
        } else {
            amount = _withdrawFromAave();
        }

        require(weth.transfer(msg.sender, amount), "WETH transfer failed");
        
        uint256 originalDeposit = depositAmount;
        depositAmount = 0;
        locationOfFunds = msg.sender;

        emit Withdraw(msg.sender, originalDeposit, locationOfFunds);
        return amount;
    }

    /**
     * @notice Rebalances funds between protocols if the APY difference exceeds threshold
     * @param _compAPY Current Compound APY
     * @param _aaveAPY Current Aave APY
     */
    function rebalance(
        uint256 _compAPY,
        uint256 _aaveAPY
    ) external nonReentrant onlyOwner ensureRebalanceCooldown checkEmergency {
        _rebalanceIfNeeded(_compAPY, _aaveAPY);
    }

    /**
     * @notice Emergency withdrawal bypassing usual checks
     */
    function emergencyWithdraw() external nonReentrant onlyEmergencyAdmin {
        require(depositAmount > 0, "No deposits to withdraw");
        
        uint256 amount;
        if (locationOfFunds == address(comet)) {
            amount = _withdrawFromCompound();
        } else {
            amount = _withdrawFromAave();
        }

        require(weth.transfer(owner(), amount), "WETH transfer failed");
        
        depositAmount = 0;
        emergencyExit = true;

        emit EmergencyWithdraw(owner(), amount, locationOfFunds);
    }

    // Internal functions
    function _rebalanceIfNeeded(uint256 _compAPY, uint256 _aaveAPY) internal {
        require(depositAmount > 0, "No deposits to rebalance");
        
        uint256 apyDiff = _compAPY > _aaveAPY ? 
            (_compAPY - _aaveAPY) : (_aaveAPY - _compAPY);
            
        if (apyDiff < rebalanceThreshold) {
            return;
        }

        if (_compAPY > _aaveAPY && locationOfFunds != address(comet)) {
            uint256 amount = _withdrawFromAave();
            _depositToCompound(amount);
            locationOfFunds = address(comet);
        } else if (_aaveAPY > _compAPY && locationOfFunds != address(aavePool)) {
            uint256 amount = _withdrawFromCompound();
            _depositToAave(amount);
            locationOfFunds = address(aavePool);
        }

        lastRebalanceTimestamp = block.timestamp;
        emit Rebalance(msg.sender, depositAmount, locationOfFunds, _compAPY, _aaveAPY);
    }

    function _collectManagementFee() internal {
        if (depositAmount == 0) return;

        uint256 timePassed = (block.timestamp - lastManagementFeeCollection);
        uint256 feeAmount = (depositAmount * managementFee * timePassed) / (365 * 1 days * BASIS_POINTS);


        if (feeAmount > 0) {
            depositAmount -= feeAmount;
            lastManagementFeeCollection = block.timestamp;
            emit ManagementFeeCollected(feeAmount);
        }
    }

    function _collectPerformanceFee() internal {
        uint256 currentBalance = locationOfFunds == address(comet) ?
            comet.balanceOf(address(this)) :
            aaveAweth.balanceOf(address(this));

        if (currentBalance > depositAmount) {
            uint256 profits = (currentBalance - depositAmount);
            uint256 feeAmount = (profits * performanceFee)/BASIS_POINTS;
            
            if (feeAmount > 0) {
                depositAmount -= feeAmount;
                emit PerformanceFeeCollected(feeAmount);
            }
        }
    }

    // Admin functions
    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function setEmergencyAdmin(address _admin, bool _status) external onlyOwner {
        emergencyAdmins[_admin] = _status;
        emit EmergencyAdminUpdated(_admin, _status);
    }

    function setFeeCollector(address _newCollector) external onlyOwner {
        require(_newCollector != address(0), "Invalid address");
        feeCollector = _newCollector;
    }

    function setPerformanceFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 3000, "Fee too high"); // Max 30%
        performanceFee = _newFee;
    }

    function setManagementFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 500, "Fee too high"); // Max 5%
        managementFee = _newFee;
    }

    // View functions
    function getCurrentProtocol() external view returns (string memory) {
        if (locationOfFunds == address(comet)) {
            return "Compound";
        } else if (locationOfFunds == address(aavePool)) {
            return "Aave";
        } else {
            return "None";
        }
    }

    function getContractBalance() external view returns (uint256) {
        return weth.balanceOf(address(this));
    }

    // Existing helper functions remain unchanged
    function _getAavePool() private view returns (IPool) {
        return IPool(IPoolAddressesProvider(AaveV3PoolAddressProvider).getPool());
    }

    function _depositToAave(uint256 weth_amount) private {
        aavePool = _getAavePool();
        require(weth.approve(address(aavePool), weth_amount), "WETH approval failed");
        aavePool.supply(address(weth), weth_amount, address(this), 0);
        locationOfFunds = address(aavePool);
    }

    function _depositToCompound(uint256 weth_amount) private {
        require(weth.approve(address(comet), weth_amount), "WETH approval failed");
        comet.supply(address(weth), weth_amount);
        locationOfFunds = address(comet);
    }

    function _withdrawFromCompound() private returns (uint256) {
        uint256 balance = comet.balanceOf(address(this));
        comet.withdraw(address(weth), balance);
        return weth.balanceOf(address(this));
    }

    function _withdrawFromAave() private returns (uint256) {
        aavePool = _getAavePool();
        uint256 balance = aaveAweth.balanceOf(address(this));
        require(aaveAweth.approve(address(aavePool), balance), "aWETH approval failed");
        aavePool.withdraw(address(weth), type(uint).max, address(this));
        return weth.balanceOf(address(this));
    }
}
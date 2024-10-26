// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStrategy} from "./IStrategy.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

error CallerIsNotYieldVault();
error DepositAmountMustBeGreaterThanZero();
error WithdrawalAmountMustBeGreaterThanZero();

contract AaveStrategy is IStrategy {
    using SafeERC20 for IERC20;

    address public immutable asset; // The token this strategy accepts (e.g., WETH, DAI, USDC)
    address public immutable vault; // The YieldVault contract address

    IPool public aavePool; // The Aave lending pool interface
    IERC20 public immutable assetToken; // ERC-20 interface for the asset

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);

    modifier onlyVault() {
        if (msg.sender != vault) revert CallerIsNotYieldVault();
        _;
    }

    /// @param _asset The address of the asset managed by the vault (e.g., WETH, DAI, USDC)
    /// @param _vault The address of the YieldVault contract
    /// @param _poolAddressesProvider The address of AaveV3 Pool Provider - 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A ();
    /// It is gotten from their website - https://aave.com/docs/resources/addresses
    constructor(address _asset, address _vault, address _poolAddressesProvider) {
        asset = _asset;
        vault = _vault;
        assetToken = IERC20(_asset);

        // Initialize Aave pool from the provider
        IPoolAddressesProvider provider = IPoolAddressesProvider(_poolAddressesProvider);
        aavePool = IPool(provider.getPool());
    }

    /// @notice Deposits funds into Aave
    /// @param amount The amount of asset to deposit
    function invest(uint256 amount) external onlyVault {
        if (amount == 0) revert DepositAmountMustBeGreaterThanZero();

        // Transfer asset to this contract
        assetToken.safeTransferFrom(vault, address(this), amount);

        // Approve Aave to pull the asset for deposit
        assetToken.approve(address(aavePool), amount);

        // Deposit into Aave, using the vault as the recipient
        aavePool.supply(asset, amount, address(this), 0);

        emit Deposited(amount);
    }

    /// @notice Withdraws funds from Aave to the YieldVault
    /// @param amount The amount of asset to withdraw
    function withdraw(uint256 amount) external onlyVault {
        if (amount == 0) revert WithdrawalAmountMustBeGreaterThanZero();

        // Withdraw from Aave to this contract
        uint256 withdrawnAmount = aavePool.withdraw(asset, amount, address(this));

        // Transfer the withdrawn asset to the YieldVault
        assetToken.safeTransferFrom(address(this), address(vault), withdrawnAmount);

        emit Withdrawn(withdrawnAmount);
    }

    // Get total assets held by the strategy (deposited in Aave)
    function totalBalance() public view returns (uint256) {
        return assetToken.balanceOf(address(this));
    }

    // Expected return based on Aave's current interest rate (for estimation purposes)
    function expectedReturn() public pure returns (uint256) {
        // TODO: Add logic to calculate APY (Use Chainlink price feeds for dynamic calculations)
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error NotAuthorized();
abstract contract Strategy {
    address public vault;  // Vault that interacts with the strategy
    address public want;   // The token the strategy works with (e.g., DAI, USDC)

    constructor(address _vault, address _want) {
        vault = _vault;
        want = _want;
    }

    // Modifier to restrict access to only the vault
    modifier onlyVault() {
        if(msg.sender != vault) revert NotAuthorized();
        _;
    }

    // Deposit funds into the strategy (only callable by the vault)
    function deposit(uint256 amount) external virtual onlyVault;

    // Withdraw funds from the strategy (only callable by the vault)
    function withdraw(uint256 amount) external virtual onlyVault returns (uint256);

    // Return the total value managed by this strategy
    function balanceOf() external view virtual returns (uint256);

    // Harvest the yield (only callable by the vault)
    function harvest() external virtual onlyVault;

    // Emergency withdraw all funds from the strategy
    function emergencyWithdraw() external virtual onlyVault returns (uint256);
}

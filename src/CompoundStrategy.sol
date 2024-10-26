// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "./IStrategy.sol";
// import "./YieldVault.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// interface ICompound {
//     function mint(uint256 mintAmount) external returns (uint256);
//     function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
// }

// contract CompoundStrategy is IStrategy, Ownable {
//     using SafeERC20 for IERC20;

//     ICompound public compound;
//     IERC20 public asset;
//     YieldVault public vault;

//     constructor(address _compound, address _asset, address _vault) Ownable(msg.sender) {
//         compound = ICompound(_compound);
//         asset = IERC20(_asset);
//         vault = YieldVault(_vault);
//     }

//     // Deposit funds into Compound
//     function invest() external override onlyOwner {
//         uint256 balance = asset.balanceOf(address(this));
//         if (balance > 0) {
//             asset.approve(address(compound), balance);
//             compound.mint(balance);
//         }
//     }

//     // Withdraw funds from Compound
//     function withdraw(uint256 amount) external override onlyOwner returns (uint256) {
//         uint256 redeemed = compound.redeemUnderlying(amount);
//         return redeemed;
//     }

//     // Harvest profits (interest earned) and send them to the vault
//     function harvest() external override onlyOwner returns (uint256 profit) {
//         uint256 totalAssets = estimatedTotalAssets();
//         uint256 currentVaultAssets = vault.totalAssets();

//         if (totalAssets > currentVaultAssets) {
//             profit = totalAssets - currentVaultAssets;
//             asset.safeTransfer(address(vault), profit);
//         }

//         return profit;
//     }

//     // Get total assets held by the strategy (deposited in Compound)
//     function estimatedTotalAssets() public view override returns (uint256) {
//         return asset.balanceOf(address(this));
//     }

//     // Expected return based on Compound's current interest rate
//     function expectedReturn() public pure override returns (uint256) {
//         // TODO: Add logic to calculate Compound's interest rate
//         return 0;
//     }
// }

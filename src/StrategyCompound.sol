// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "./Strategy.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@compound-protocol/contracts/CErc20.sol";

// contract StrategyCompound is Strategy {
//     CErc20 public cToken;

//     constructor(address _vault, address _want, address _cToken) Strategy(_vault, _want) {
//         cToken = CErc20(_cToken);
//     }

//     // Deposit tokens into Compound
//     function deposit(uint256 amount) external override onlyVault {
//         IERC20(want).approve(address(cToken), amount);
//         require(cToken.mint(amount) == 0, "Compound mint failed"); // Deposit into Compound
//     }

//     // Withdraw tokens from Compound
//     function withdraw(uint256 amount) external override onlyVault returns (uint256) {
//         require(cToken.redeemUnderlying(amount) == 0, "Compound redeem failed");
//         return amount; // Return the amount withdrawn
//     }

//     // Get the total balance (cToken balance)
//     function balanceOf() external view override returns (uint256) {
//         return cToken.balanceOfUnderlying(address(this)); // Return balance of underlying tokens
//     }

//     // Harvest yield (Compound's yield is stored in cTokens)
//     function harvest() external override onlyVault {
//         // Compound auto-compounds, so no manual harvesting is needed.
//     }

//     // Emergency withdraw all funds
//     function emergencyWithdraw() external override onlyVault returns (uint256) {
//         uint256 balance = cToken.balanceOfUnderlying(address(this));
//         cToken.redeem(balance); // Withdraw everything
//         return balance;
//     }
// }

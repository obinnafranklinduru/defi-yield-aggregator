// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "./Strategy.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";

// contract StrategyAAVE is Strategy {
//     ILendingPool public lendingPool;
//     IERC20 public aToken;

//     constructor(address _vault, address _want, address _lendingPool, address _aToken) Strategy(_vault, _want) {
//         lendingPool = ILendingPool(_lendingPool);
//         aToken = IERC20(_aToken);
//     }

//     // Deposit tokens into Aave
//     function deposit(uint256 amount) external override onlyVault {
//         IERC20(want).approve(address(lendingPool), amount);
//         lendingPool.deposit(want, amount, address(this), 0); // Deposit into Aave
//     }

//     // Withdraw tokens from Aave
//     function withdraw(uint256 amount) external override onlyVault returns (uint256) {
//         uint256 initialBalance = IERC20(want).balanceOf(address(this));
//         lendingPool.withdraw(want, amount, address(this)); // Withdraw from Aave
//         uint256 finalBalance = IERC20(want).balanceOf(address(this));
//         return finalBalance - initialBalance; // Return the actual amount withdrawn
//     }

//     // Get the total balance (aToken balance)
//     function balanceOf() external view override returns (uint256) {
//         return aToken.balanceOf(address(this)); // Return balance of aTokens
//     }

//     // Harvest yield (for Aave, yield is auto-compounded in aTokens)
//     function harvest() external override onlyVault {
//         // Aave auto-compounds interest, so no manual harvesting is needed.
//     }

//     // Emergency withdraw all funds
//     function emergencyWithdraw() external override onlyVault returns (uint256) {
//         uint256 balance = aToken.balanceOf(address(this));
//         lendingPool.withdraw(want, balance, address(this)); // Withdraw everything
//         return balance;
//     }
// }

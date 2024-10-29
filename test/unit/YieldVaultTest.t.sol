// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "forge-std/Test.sol";
// import "forge-std/Console.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {MockToken} from "../mocks/MockToken.sol";
// import {YieldVault} from "../../src/YieldVault.sol";
// import {AaveStrategy} from "../../src/AaveStrategy.sol";

// contract YieldVaultTest is Test {
//     YieldVault vault;
//     AaveStrategy aaveStrategy;
//     MockToken token;

//     address OWNER = makeAddr("owner");
//     address USER = makeAddr("user");
//     address aavePoolProvider = address(0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A);

//     function setUp() public {
//         token = new MockToken();

//         // Deploy the vault contract with the mock token
//         vm.prank(OWNER);
//         vault = new YieldVault(address(token), "Yield Vault Token", "YVT");

//         aaveStrategy = new AaveStrategy(address(token), address(yieldVault), aavePoolProvider);

//         vault.setStrategy(address(aaveStrategy));

//         vault.setStrategy(address(aaveStrategy));

//         token.mint(USER, 1_000 * 1e18);
//     }

//     function testDeposit() public {
//         vm.startPrank(USER);
//         uint256 depositAmount = 100 * 1e18;

//         token.approve(address(vault), depositAmount);

//         uint256 initialTotalAssets = vault.totalAssets();
//         uint256 initialUserShares = vault.balanceOf(user);

//         assertEq(vault.balanceOf(USER), depositAmount);
//         assertEq(vault.totalAssets(), depositAmount);
//         vm.stopPrank();

//         uint256 shares = yieldVault.deposit(depositAmount);

//         assertEq(vault.totalAssets(), initialTotalAssets + depositAmount, "Total assets should increase by deposit amount");
//         assertEq(yieldVault.balanceOf(user), initialUserShares + shares, "User should receive corresponding shares");

//         vm.stopPrank();
//     }

//     // function testWithdraw() public {
//     //     // User deposits tokens first
//     //     vm.startPrank(USER);
//     //     token.approve(address(vault), 500 ether);

//     //     uint256 depositAmount = 100 ether;
//     //     vault.deposit(depositAmount);

//     //     uint256 withdrawAmount = 50 ether;
//     //     vault.withdraw(withdrawAmount);

//     //     assertEq(vault.balanceOf(USER), 50 ether); // User has 50 shares left
//     //     assertEq(vault.totalAssets(), 50 ether); // Vault's total assets decrease
//     //     assertEq(token.balanceOf(USER), 950 ether); // User got 50 tokens back
//     // }

//     // function testFailZeroDeposit() public {
//     //     vm.startPrank(USER);
//     //     vault.deposit(0); // Should fail
//     // }

//     // function testFailWithdrawMoreThanBalance() public {
//     //     // Test user trying to withdraw more than they deposited
//     //     vm.startPrank(USER);
//     //     token.approve(address(vault), 500 ether);
//     //     vault.deposit(100 ether);
//     //     vault.withdraw(200 ether); // Should fail
//     // }

//     // function testEmergencyPause() public {
//     //     // Only the owner can pause the contract
//     //     vm.prank(OWNER);
//     //     vault.pause();

//     //     // Expect revert when trying to deposit during emergency shutdown
//     //     vm.prank(USER);
//     //     vm.expectRevert();
//     //     vault.deposit(100 ether);

//     //     // Expect revert when trying to withdraw during emergency shutdown
//     //     vm.prank(USER);
//     //     vm.expectRevert();
//     //     vault.withdraw(100 ether);
//     // }

//     // function testUnpause() public {
//     //     // Pause and then unpause the contract
//     //     vm.prank(OWNER);
//     //     vault.pause();
//     //     vm.prank(OWNER);
//     //     vault.unpause();

//     //     // Now the user can deposit and withdraw again
//     //     vm.startPrank(USER);
//     //     token.approve(address(vault), 500 ether);
//     //     vault.deposit(500 ether);

//     //     // Check that deposit worked after unpause
//     //     assertEq(token.balanceOf(address(vault)), 500 ether);
//     //     vm.stopPrank();
//     // }
// }

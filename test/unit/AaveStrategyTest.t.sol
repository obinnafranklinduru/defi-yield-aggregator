// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {YieldVault} from "../../src/YieldVault.sol";
import {MockToken} from "../mocks/MockToken.sol";
import {AaveStrategy} from "../../src/AaveStrategy.sol";

// contract AaveStrategyTest is Test {
//     AaveStrategy strategy;
//     YieldVault vault;
//     MockToken token;

//     address USER = makeAddr("user");
//     address OWNER = makeAddr("owner");
//     uint256 constant STARTING_BALANCE = 100 ether;

//     function setUp() public {
//         vm.deal(USER, STARTING_BALANCE);
//         vm.deal(OWNER, STARTING_BALANCE);

//         // Set up the mock Aave contract, vault, and token
//         token = new MockToken();
//         token.mint(address(this), 1000 ether);

//         vm.prank(OWNER);
//         vault = new YieldVault(address(token), "Vault Token", "vMTK");

//         vm.prank(OWNER);
//         strategy = new AaveStrategy(address(this), address(token), address(vault));
//         vault.setStrategy(strategy);
//     }

//     function testInvest() public {
//         vm.startPrank(USER);
//         token.approve(address(vault), 100 ether);

//         vault.deposit(100 ether);

//         // Assert that the funds have been invested in Aave
//         assertEq(token.balanceOf(address(strategy)), 0); // All tokens should be in Aave
//         vm.stopPrank();
//     }

//     function testWithdraw() public {
//         vm.startPrank(USER);
//         token.approve(address(vault), 100 ether);
//         vault.deposit(100 ether);

//         vault.withdraw(50 ether);
//         assertEq(token.balanceOf(address(this)), 50 ether); // Tokens should be returned to user
//         vm.stopPrank();
//     }
// }

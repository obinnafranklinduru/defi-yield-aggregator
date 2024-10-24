// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/YieldVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing purposes
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract YieldVaultTest is Test {
    YieldVault vault;
    MockToken token;

    address USER = makeAddr("user");
    address OWNER = makeAddr("owner");
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        // Deploy the mock token and mint some tokens for testing
        token = new MockToken();
        token.mint(USER, 1000 ether);  // Mint 1000 tokens to the user

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(OWNER, STARTING_BALANCE);

        // Deploy the vault contract with the mock token
        vm.prank(OWNER);
        vault = new YieldVault(address(token));

        // Set the vault owner
        vm.startPrank(OWNER);
        vault.transferOwnership(OWNER);
        vm.stopPrank();
    }

    function testDeposit() public {
        // User approves the vault to spend tokens
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);

        // User deposits tokens into the vault
        vault.deposit(500 ether);

        // Check the vault balance and user balance
        assertEq(token.balanceOf(address(vault)), 500 ether);
        assertEq(vault.userBalances(USER), 500 ether);
        vm.stopPrank();
    }

    function testWithdraw() public {
        // User deposits tokens first
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);
        vault.deposit(500 ether);

        // User withdraws tokens
        vault.withdraw(200 ether);

        // Check balances after withdrawal
        assertEq(token.balanceOf(USER), 700 ether);  // 1000 - 500 + 200
        assertEq(vault.userBalances(USER), 300 ether);  // 500 - 200
        vm.stopPrank();
    }

    function testInsufficientWithdraw() public {
        // User deposits 500 tokens
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);
        vault.deposit(500 ether);

        // Try to withdraw more than balance, expecting a revert with InsufficientBalance
        vm.expectRevert();
        vault.withdraw(600 ether);

        vm.stopPrank();
    }

    function testEmergencyPause() public {
        // Only the owner can pause the contract
        vm.prank(OWNER);
        vault.pause();

        // Expect revert when trying to deposit during emergency shutdown
        vm.prank(USER);
        vm.expectRevert();
        vault.deposit(100 ether);

        // Expect revert when trying to withdraw during emergency shutdown
        vm.prank(USER);
        vm.expectRevert();
        vault.withdraw(100 ether);
    }

    function testUnpause() public {
        // Pause and then unpause the contract
        vm.prank(OWNER);
        vault.pause();
        vm.prank(OWNER);
        vault.unpause();

        // Now the user can deposit and withdraw again
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);
        vault.deposit(500 ether);

        // Check that deposit worked after unpause
        assertEq(token.balanceOf(address(vault)), 500 ether);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/YieldVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing purposes
contract MockToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract YieldVaultTest is Test {
    YieldVault vault;
    MockToken token;

    address USER = makeAddr("user");
    address OWNER = makeAddr("owner");
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(OWNER, STARTING_BALANCE);

        token = new MockToken("MockToken", "MTK");
        token.mint(USER, 1000 ether);
        token.mint(OWNER, 1000 ether);

        // Deploy the vault contract with the mock token
        vm.prank(OWNER);
        vault = new YieldVault(address(token), "Vault Token", "vMTK");
    }

    function testDeposit() public {
        vm.startPrank(USER);
        token.approve(address(vault), 100 ether);

        uint256 depositAmount = 100 ether;
        vault.deposit(depositAmount);
        
        assertEq(vault.balanceOf(USER), depositAmount); // 1:1 share ratio at start
        assertEq(vault.totalAssets(), depositAmount);
        vm.stopPrank();
    }

    function testWithdraw() public {
        // User deposits tokens first
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);

        uint256 depositAmount = 100 ether;
        vault.deposit(depositAmount);
        
        uint256 withdrawAmount = 50 ether;
        vault.withdraw(withdrawAmount);

        assertEq(vault.balanceOf(USER), 50 ether); // User has 50 shares left
        assertEq(vault.totalAssets(), 50 ether);   // Vault's total assets decrease
        assertEq(token.balanceOf(USER), 950 ether); // User got 50 tokens back
    }

    function testFailZeroDeposit() public {
        vm.startPrank(USER);
        vault.deposit(0);  // Should fail
    }

    function testFailWithdrawMoreThanBalance() public {
        // Test user trying to withdraw more than they deposited
        vm.startPrank(USER);
        token.approve(address(vault), 500 ether);
        vault.deposit(100 ether);
        vault.withdraw(200 ether);  // Should fail
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

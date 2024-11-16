// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockAavePool} from "./mocks/MockAavePool.sol";
import {MockCompound} from "./mocks/MockCompound.sol";

contract YieldAggregatorTest is Test {
    YieldAggregator public yieldAggregator;
    MockERC20 public weth;
    MockAavePool public aavePool;
    MockCompound public compoundPool;

    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant FEE_COLLECTOR = address(0x3);

    uint256 public constant INITIAL_DEPOSIT = 1 ether;
    uint256 public constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        aavePool = new MockAavePool();
        compoundPool = new MockCompound();

        yieldAggregator = new YieldAggregator(
            address(weth),
            address(weth),
            address(compoundPool),
            address(aavePool),
            address(aavePool),
            FEE_COLLECTOR
        );

        vm.startPrank(ALICE);
        weth.mint(ALICE, INITIAL_BALANCE);
        weth.approve(address(yieldAggregator), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(BOB);
        weth.mint(BOB, INITIAL_BALANCE);
        weth.approve(address(yieldAggregator), type(uint256).max);
        vm.stopPrank();

        weth.mint(address(compoundPool), 100 ether);
        weth.mint(address(aavePool), 100 ether);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        uint256 compAPY = 5; // 5% APY
        uint256 aaveAPY = 4; // 4% APY

        vm.startPrank(ALICE);
        yieldAggregator.deposit(depositAmount, compAPY, aaveAPY);

        // Check user deposit
        (uint256 principal, uint256 yield) = yieldAggregator.getUserValue(ALICE);
        assertEq(principal, depositAmount, "Incorrect deposit amount");
        assertEq(yield, 0, "Initial yield should be zero");

        // Check protocol selection (should be Compound due to higher APY)
        (YieldAggregator.ProtocolType protocol, uint256 totalValue) = yieldAggregator.getCurrentProtocolInfo();
        assertEq(uint256(protocol), uint256(YieldAggregator.ProtocolType.COMPOUND), "Wrong protocol selected");
        assertEq(totalValue, depositAmount, "Incorrect total value");
        vm.stopPrank();
    }

    function testWithdraw() public {
        // First deposit
        uint256 depositAmount = 1 ether;
        vm.startPrank(ALICE);
        yieldAggregator.deposit(depositAmount, 5, 4);

        // Mock some yield generation
        // Approve yield transfer from Compound to YieldAggregator
        vm.startPrank(address(compoundPool));
        weth.approve(address(yieldAggregator), type(uint256).max);
        compoundPool.mockYield(address(yieldAggregator), 0.1 ether);
        vm.stopPrank();

        vm.startPrank(ALICE);
        // Withdraw
        uint256 withdrawnAmount = yieldAggregator.withdraw();
        
        // Check withdrawn amount (original deposit + yield - fees)
        assertTrue(withdrawnAmount > depositAmount, "Should withdraw more than deposit due to yield");
        assertEq(weth.balanceOf(ALICE), INITIAL_BALANCE - depositAmount + withdrawnAmount, "Incorrect final balance");
        vm.stopPrank();
    }

    function testRebalancing() public {
        vm.startPrank(ALICE);
        yieldAggregator.deposit(1 ether, 5, 4); // Initial deposit to Compound (higher APY)

        // Time passes, APYs change
        vm.warp(block.timestamp + 1 days);

        // Ensure protocols have necessary approvals
        vm.startPrank(address(compoundPool));
        weth.approve(address(yieldAggregator), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(address(aavePool));
        weth.approve(address(yieldAggregator), type(uint256).max);
        vm.stopPrank();

        // Rebalance to Aave due to better rates
        vm.startPrank(address(yieldAggregator.owner()));
        yieldAggregator.rebalance(4, 6); // Now Aave has better APY

        // Verify rebalance
        (YieldAggregator.ProtocolType protocol,) = yieldAggregator.getCurrentProtocolInfo();
        assertEq(uint256(protocol), uint256(YieldAggregator.ProtocolType.AAVE), "Failed to rebalance to Aave");
        vm.stopPrank();
    }

    function testEmergencyControls() public {
        vm.startPrank(ALICE);
        yieldAggregator.deposit(1 ether, 5, 4);
        vm.stopPrank();

        // Setup emergency admin and protocol approvals
        vm.startPrank(address(compoundPool));
        weth.approve(address(yieldAggregator), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(address(yieldAggregator.owner()));
        // Trigger emergency withdrawal
        yieldAggregator.emergencyWithdraw();

        // Verify emergency state
        (YieldAggregator.ProtocolType protocol, uint256 totalValue) = yieldAggregator.getCurrentProtocolInfo();
        assertEq(uint256(protocol), uint256(YieldAggregator.ProtocolType.NONE), "Protocol not reset");
        assertEq(totalValue, 0, "Total value not zero");

        // Try to deposit during emergency (should fail)
        vm.expectRevert();
        yieldAggregator.deposit(1 ether, 5, 4);
        vm.stopPrank();
    }

    function testFuzzDeposit(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 0.1 ether, 100 ether);
        
        vm.startPrank(ALICE);
        weth.mint(ALICE, amount);
        yieldAggregator.deposit(amount, 5, 4);
        
        (uint256 principal,) = yieldAggregator.getUserValue(ALICE);
        assertEq(principal, amount, "Fuzzing: Incorrect deposit amount");
        vm.stopPrank();
    }

    receive() external payable {}
}

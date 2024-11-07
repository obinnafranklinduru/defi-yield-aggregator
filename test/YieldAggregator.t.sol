// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IComet} from "../src/IComet.sol";
import {console2} from "forge-std/console2.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployYieldAggregator} from "../script/YieldAggregator.s.sol";

contract YieldAggregatorTest is Test {
    YieldAggregator public yieldAggregator;
    IERC20 public weth;
    IComet public cometWeth;
    IPool public aavePool;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant AAVE_WETH_ADDRESS = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address public constant COMPOUND_PROXY = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address public constant AAVE_POOL_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address public constant AAVE_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant FEE_COLLECTOR = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address public owner;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_DEPOSIT = 10 ether;
    uint256 public constant REBALANCE_COOLDOWN = 1 days;

    struct UserDeposit {
        uint256 amount;
        uint256 lastDepositTime;
        uint256 accumulatedYield;
    }

    struct Fees {
        uint96 annualManagementFeeInBasisPoints;
        uint96 performanceFee;
        uint64 lastRebalanceTimestamp;
    }

    enum ProtocolType {
        NONE,
        COMPOUND,
        AAVE
    }

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        DeployYieldAggregator deployYieldAggregator = new DeployYieldAggregator();
        yieldAggregator = deployYieldAggregator.run();

        weth = IERC20(WETH_ADDRESS);
        cometWeth = IComet(COMPOUND_PROXY);
        aavePool = IPool(AAVE_POOL_ADDRESS);

        // Mint some WETH for testing
        vm.deal(owner, 50 ether);
        weth.approve(address(yieldAggregator), 50 ether);

        // Transfer WETH to user1 and user2
        weth.transfer(user1, INITIAL_DEPOSIT);
        weth.transfer(user2, INITIAL_DEPOSIT);

        // Approve YieldAggregator to spend WETH for all users
        vm.prank(user1);
        weth.approve(address(yieldAggregator), 50 ether);

        vm.prank(user2);
        weth.approve(address(yieldAggregator), 50 ether);
    }

    function testDisply() public {
        vm.startPrank(user1);
        assertEq(true, true);
        vm.stopPrank();
    }

    // function testDeposit() public {
    //     uint256 compAPY = 500; // 5%
    //     uint256 aaveAPY = 300; // 3%

    //     vm.startPrank(user1);
    //     yieldAggregator.deposit(INITIAL_DEPOSIT, compAPY, aaveAPY);
    //     vm.stopPrank();

    //     UserDeposit memory userDeposit = yieldAggregator.userDeposits(user1);
    //     uint256 amount = userDeposit.amount;
    //     assertEq(amount, INITIAL_DEPOSIT, "User amount should be INITIAL_DEPOSIT");
    //     assertEq(yieldAggregator.totalDeposits(), INITIAL_DEPOSIT);
    //     assertEq(yieldAggregator.currentProtocol(), uint256(YieldAggregator.ProtocolType.COMPOUND));
    // }

    // function testRevertDepositWithZeroAmount() public {
    //     vm.startPrank(user1);
    //     vm.expectRevert(abi.encodeWithSelector(YieldAggregator.YieldAggregator__InsufficientBalance.selector, 0, 0));
    //     yieldAggregator.deposit(0, 500, 300);
    //     vm.stopPrank();
    // }

    // function testWithdrawal() public {
    //     vm.startPrank(user1);
    //     yieldAggregator.deposit(INITIAL_DEPOSIT, 500, 300);
    //     uint256 withdrawnAmount = yieldAggregator.withdraw();
    //     vm.stopPrank();

    //     UserDeposit memory userDeposit = yieldAggregator.userDeposits(user1);
    //     assertEq(userDeposit.amount, 0);
    //     assertGt(withdrawnAmount, 0);
    // }

    // function testRebalance() public {
    //     vm.startPrank(user1);
    //     yieldAggregator.deposit(INITIAL_DEPOSIT, 300, 500);
    //     vm.stopPrank();

    //     vm.warp(block.timestamp + REBALANCE_COOLDOWN);

    //     ProtocolType initialProtocol = yieldAggregator.currentProtocol();

    //     vm.startPrank(owner);
    //     yieldAggregator.rebalance(500, 300);
    //     vm.stopPrank();

    //     ProtocolType newProtocol = yieldAggregator.currentProtocol();
    //     // assertNotEqual(uint256(newProtocol), uint256(initialProtocol));
    // }

    // function testEmergencyWithdrawal() public {
    //     vm.startPrank(user1);
    //     yieldAggregator.deposit(INITIAL_DEPOSIT, 500, 300);
    //     vm.stopPrank();

    //     uint256 balanceBefore = weth.balanceOf(owner);

    //     vm.startPrank(owner);
    //     yieldAggregator.emergencyWithdraw();
    //     vm.stopPrank();

    //     uint256 balanceAfter = weth.balanceOf(owner);
    //     //assertNotEqual(balanceAfter, balanceBefore);
    //     assertTrue(yieldAggregator.emergencyExitEnabled());
    // }

    // function testUpdateProtocolConfiguration() public {
    //     address newFeeCollector = user2;
    //     uint96 newManagementFee = 200; // 2%
    //     uint96 newPerformanceFee = 2000; // 20%

    //     vm.startPrank(owner);
    //     yieldAggregator.updateProtocolConfiguration(
    //         newFeeCollector,
    //         newManagementFee,
    //         newPerformanceFee
    //     );
    //     vm.stopPrank();

    //     assertEq(yieldAggregator.feeCollector(), newFeeCollector);

    //     Fees memory fees = yieldAggregator.fees();
    //     assertEq(fees.annualManagementFeeInBasisPoints, newManagementFee);
    //     assertEq(fees.performanceFee, newPerformanceFee);
    // }

    // function testRevertInvalidFeeUpdate() public {
    //     uint96 invalidManagementFee = 600;

    //     vm.startPrank(owner);
    //     vm.expectRevert(abi.encodeWithSelector(YieldAggregator.YieldAggregator__FeeTooHigh.selector, invalidManagementFee, YieldAggregator.MAX_MANAGEMENT_FEE));
    //     yieldAggregator.updateProtocolConfiguration(
    //         user2,
    //         invalidManagementFee,
    //         2000
    //     );
    //     vm.stopPrank();
    // }
}

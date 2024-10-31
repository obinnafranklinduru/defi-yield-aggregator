// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldAggregatorTest is Test {
    YieldAggregator public aggregator;
    address public owner;
    address public feeCollector;
    
    // Mainnet addresses
    address constant AAVE_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant COMPOUND = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;
    address constant AAVE_WETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    
    // WETH whale address for testing
    address constant WETH_WHALE = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    
    function setUp() public {
        owner = address(this);
        feeCollector = address(0x123);
        
        // Deploy the aggregator
        aggregator = new YieldAggregator(
            AAVE_PROVIDER,
            WETH,
            COMPOUND,
            AAVE_WETH,
            feeCollector
        );
        
        // Fork mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        
        // Impersonate WETH whale
        vm.startPrank(WETH_WHALE);
        IERC20(WETH).approve(address(aggregator), type(uint256).max);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(aggregator.owner(), owner);
        assertEq(aggregator.feeCollector(), feeCollector);
        assertEq(aggregator.depositAmount(), 0);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        uint256 compAPY = 500; // 5%
        uint256 aaveAPY = 400; // 4%

        // Simulate WETH whale depositing
        vm.startPrank(WETH_WHALE);
        
        // Get WETH balance before
        uint256 balanceBefore = IERC20(WETH).balanceOf(WETH_WHALE);
        
        // Deposit
        aggregator.deposit(depositAmount, compAPY, aaveAPY);
        
        // Verify deposit
        assertEq(aggregator.depositAmount(), depositAmount);
        assertEq(
            IERC20(WETH).balanceOf(WETH_WHALE),
            balanceBefore - depositAmount
        );
        assertEq(aggregator.locationOfFunds(), COMPOUND); // Should be in Compound as it has higher APY
        
        vm.stopPrank();
    }

    function testRebalance() public {
        uint256 depositAmount = 1 ether;
        
        // Initial deposit to Compound (higher APY)
        vm.startPrank(WETH_WHALE);
        aggregator.deposit(depositAmount, 500, 400);
        vm.stopPrank();
        
        // Advance time to pass rebalance cooldown
        vm.warp(block.timestamp + 1 days + 1);
        
        // Rebalance to Aave (now higher APY)
        aggregator.rebalance(400, 600);
        
        // Verify funds moved to Aave
        assertEq(aggregator.locationOfFunds(), address(aggregator.aavePool()));
    }

    function testEmergencyWithdraw() public {
        uint256 depositAmount = 1 ether;
        
        // Initial deposit
        vm.startPrank(WETH_WHALE);
        aggregator.deposit(depositAmount, 500, 400);
        vm.stopPrank();
        
        // Set emergency admin
        aggregator.setEmergencyAdmin(owner, true);
        
        // Emergency withdraw
        uint256 balanceBefore = IERC20(WETH).balanceOf(owner);
        aggregator.emergencyWithdraw();
        
        // Verify withdrawal
        assertTrue(aggregator.emergencyExit());
        assertEq(aggregator.depositAmount(), 0);
        assertTrue(IERC20(WETH).balanceOf(owner) > balanceBefore);
    }

    function testFeeCollection() public {
        uint256 depositAmount = 1 ether;
        
        // Initial deposit
        vm.startPrank(WETH_WHALE);
        aggregator.deposit(depositAmount, 500, 400);
        vm.stopPrank();
        
        // Advance time 1 year
        vm.warp(block.timestamp + 365 days);
        
        // Withdraw to trigger fee collection
        uint256 balanceBefore = IERC20(WETH).balanceOf(feeCollector);
        aggregator.withdraw();
        
        // Verify fees collected
        assertTrue(IERC20(WETH).balanceOf(feeCollector) > balanceBefore);
    }

    // Add more test cases as needed...
}
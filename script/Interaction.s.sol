// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldAggregatorInteraction is Script {
    YieldAggregator public aggregator;
    IERC20 public weth;
    
    // Replace with your deployed aggregator address
    address constant AGGREGATOR_ADDRESS = address(0); // TODO: Replace with actual address
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        aggregator = YieldAggregator(AGGREGATOR_ADDRESS);
        weth = IERC20(WETH_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);

        // Example interaction flow
        checkAndPrintBalances();
        depositFunds();
        checkYieldAndRebalance();
        withdrawFunds();

        vm.stopBroadcast();
    }

    function checkAndPrintBalances() internal view {
        uint256 contractBalance = aggregator.getContractBalance();
        string memory currentProtocol = aggregator.getCurrentProtocol();
        uint256 totalDeposits = aggregator.depositAmount();

        console.log("Contract WETH Balance:", contractBalance);
        console.log("Current Protocol:", currentProtocol);
        console.log("Total Deposits:", totalDeposits);
    }

    function depositFunds() internal {
        uint256 depositAmount = 1 ether;
        
        // First approve WETH
        weth.approve(address(aggregator), depositAmount);

        // Get mock APY rates (in practice, you'd get these from an oracle or API)
        uint256 compoundAPY = 500; // 5%
        uint256 aaveAPY = 400; // 4%

        // Deposit
        aggregator.deposit(depositAmount, compoundAPY, aaveAPY);
        console.log("Deposited:", depositAmount);
    }

    function checkYieldAndRebalance() internal {
        // In practice, you'd get these rates from an oracle or API
        uint256 newCompoundAPY = 400; // 4%
        uint256 newAaveAPY = 600; // 6%

        // Check if rebalance is needed and execute
        if (block.timestamp >= aggregator.lastRebalanceTimestamp() + 1 days) {
            aggregator.rebalance(newCompoundAPY, newAaveAPY);
            console.log("Rebalanced to highest yield protocol");
        }
    }

    function withdrawFunds() internal {
        uint256 amountWithdrawn = aggregator.withdraw();
        console.log("Withdrawn amount:", amountWithdrawn);
    }
}
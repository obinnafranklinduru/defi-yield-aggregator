// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract InteractWithAggregator is Script {
    YieldAggregator public aggregator;
    IERC20 public weth;

    function setUp(address mostRecentlyDeployed) public {
        // Load deployed contract address from .env
        address payable aggregatorAddress = payable(mostRecentlyDeployed);
        aggregator = YieldAggregator(aggregatorAddress);
        weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function depositToAggregator() public {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);

        uint256 amount = 0.1 ether;

        // Approve aggregator to spend WETH
        weth.approve(address(aggregator), amount);

        // Mock APY rates (example values)
        uint256 compoundAPY = 500; // 5%
        uint256 aaveAPY = 450; // 4.5%

        // Deposit
        aggregator.deposit(amount, compoundAPY, aaveAPY);

        console2.log("Deposited:", amount);

        vm.stopBroadcast();
    }

    function withdrawFromAggregator() public {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);

        // Withdraw all funds
        uint256 withdrawn = aggregator.withdraw();

        console2.log("Withdrawn amount:", withdrawn);

        vm.stopBroadcast();
    }

    function rebalanceProtocol() public {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        vm.startBroadcast(adminPrivateKey);

        // Mock APY rates
        uint256 compoundAPY = 600; // 6%
        uint256 aaveAPY = 650; // 6.5%

        aggregator.rebalance(compoundAPY, aaveAPY);

        console2.log("Rebalancing completed");

        vm.stopBroadcast();
    }

    function checkUserValue() public view {
        (uint256 principal, uint256 yield) = aggregator.getUserValue(msg.sender);
        console2.log("Principal:", principal);
        console2.log("Yield:", yield);
    }

    // Main entry point - you can customize which functions to run
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("YieldAggregato", block.chainid);

        console2.log("Most recently deployed YieldAggregato address: %s", mostRecentlyDeployed);

        setUp(mostRecentlyDeployed);
    }
}

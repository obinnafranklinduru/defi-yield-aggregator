// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

contract DeployYieldAggregator is Script {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant AAVE_WETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address constant COMPOUND_PROXY = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address constant AAVE_POOL_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    function run() external returns (YieldAggregator) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contract
        YieldAggregator aggregator = new YieldAggregator(
            WETH,
            AAVE_WETH,
            COMPOUND_PROXY,
            AAVE_POOL_PROVIDER,
            msg.sender // fee collector
        );

        console2.log("YieldAggregator deployed at:\n", address(aggregator));

        vm.stopBroadcast();
        return aggregator;
    }
}

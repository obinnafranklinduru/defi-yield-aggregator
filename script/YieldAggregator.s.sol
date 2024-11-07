// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

contract DeployYieldAggregator is Script {
    address constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant COMPOUND_PROXY = address(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    address constant AAVE_WETH_ADDRESS = address(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
    address constant AAVE_POOL_ADDRESS = address(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    address constant AAVE_POOL_PROVIDER = address(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);

    function run() public returns (YieldAggregator) {
        vm.startBroadcast();

        address FEE_COLLECTOR = msg.sender;

        console2.log("\nDeploying YieldAggregator with the following addresses:");
        console2.log("WETH Address:", WETH_ADDRESS);
        console2.log("Fee Collector:", FEE_COLLECTOR);
        console2.log("Compound Proxy:", COMPOUND_PROXY);
        console2.log("AAVE WETH Address:", AAVE_WETH_ADDRESS);
        console2.log("AAVE Pool Address:", AAVE_POOL_ADDRESS);
        console2.log("AAVE Pool Provider:", AAVE_POOL_PROVIDER);

        YieldAggregator yieldAggregator = new YieldAggregator(
            WETH_ADDRESS, AAVE_WETH_ADDRESS, COMPOUND_PROXY, AAVE_POOL_PROVIDER, AAVE_POOL_ADDRESS, FEE_COLLECTOR
        );

        vm.stopBroadcast();
        console2.log("\nYieldAggregator deployed to: ", address(yieldAggregator));

        return yieldAggregator;
    }
}

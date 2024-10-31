// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

contract DeployYieldAggregator is Script {
    // Mainnet addresses
    address constant AAVE_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant COMPOUND = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;
    address constant AAVE_WETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");

        vm.startBroadcast(deployerPrivateKey);

        YieldAggregator aggregator = new YieldAggregator(
            AAVE_PROVIDER,
            WETH,
            COMPOUND,
            AAVE_WETH,
            feeCollector
        );

        console.log("Aggregator deployed at:", address(aggregator));

        vm.stopBroadcast();
    }
}

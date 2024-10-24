// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/YieldVault.sol";
import "../src/StrategyAAVE.sol";
import "../src/StrategyCompound.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployVault is Script {
    function run() external {
        // Start a new script execution context
        vm.startBroadcast();

        // Deploy the YieldVault
        YieldVault vault = new YieldVault();

        // Specify the strategy parameters
        address aaveLendingPool = address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); // Aave LendingPool address
        address aDai = address(0x028171bCA77440897B824Ca71D1c56caC55b68A3); // aDAI address
        address compoundCDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643); // cDAI address
        address daiToken = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI token address

        // Deploy the AAVE strategy
        StrategyAAVE aaveStrategy = new StrategyAAVE(address(vault), daiToken, aaveLendingPool, aDai);

        // Deploy the Compound strategy
        StrategyCompound compoundStrategy = new StrategyCompound(address(vault), daiToken, compoundCDAI);

        // Optional: Add strategies to the vault
        vault.addStrategy(address(aaveStrategy));
        // vault.addStrategy(address(compoundStrategy));

        // Stop script execution context
        vm.stopBroadcast();
    }
}
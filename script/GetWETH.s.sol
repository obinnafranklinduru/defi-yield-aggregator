// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract GetWETH is Script {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);

        // Get WETH instance
        IWETH weth = IWETH(WETH);

        // Wrap 1 ETH
        uint256 amount = 1 ether;
        weth.deposit{value: amount}();

        console2.log("WETH Balance:", weth.balanceOf(msg.sender));

        vm.stopBroadcast();
    }
}

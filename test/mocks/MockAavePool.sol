// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockAavePool {
    mapping(address => uint256) public balances;
    MockERC20 public weth;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        balances[onBehalfOf] += amount;
        MockERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        MockERC20(asset).transfer(to, amount);
        return amount;
    }
}
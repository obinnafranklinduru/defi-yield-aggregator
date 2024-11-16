// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockCompound {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public yields;

    function supply(address asset, uint256 amount) external {
        balances[msg.sender] += amount;
        MockERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount) external {
        require(balances[msg.sender] + yields[msg.sender] >= amount, "Insufficient balance");
        if (amount <= balances[msg.sender]) {
            balances[msg.sender] -= amount;
        } else {
            uint256 yieldPortion = amount - balances[msg.sender];
            balances[msg.sender] = 0;
            yields[msg.sender] -= yieldPortion;
        }
        MockERC20(asset).transfer(msg.sender, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account] + yields[account];
    }

    // Test helper function to simulate yield
    function mockYield(address account, uint256 amount) external {
        yields[account] += amount;
    }
}
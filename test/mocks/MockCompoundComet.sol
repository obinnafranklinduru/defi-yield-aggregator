// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockCompoundComet {
    IERC20 public wethToken;
    mapping(address => uint256) public balanceOf;

    constructor(address _wethToken) {
        wethToken = IERC20(_wethToken);
    }

    function supply(address asset, uint256 amount) external {
        require(asset == address(wethToken), "Invalid asset");
        require(wethToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balanceOf[msg.sender] += amount;
    }

    function withdraw(address asset, uint256 amount) external {
        require(asset == address(wethToken), "Invalid asset");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        require(wethToken.transfer(msg.sender, amount), "Transfer failed");
    }
}
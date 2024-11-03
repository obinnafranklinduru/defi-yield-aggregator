// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAavePool {
    IERC20 public wethToken;
    IERC20 public aWethToken;
    mapping(address => uint256) public balances;

    constructor(address _wethToken, address _aWethToken) {
        wethToken = IERC20(_wethToken);
        aWethToken = IERC20(_aWethToken);
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16
    ) external {
        require(asset == address(wethToken), "Invalid asset");
        require(wethToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[onBehalfOf] += amount;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(asset == address(wethToken), "Invalid asset");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(wethToken.transfer(to, amount), "Transfer failed");
        return amount;
    }
}
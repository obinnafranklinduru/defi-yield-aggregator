// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStrategy {
    function invest(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function totalBalance() external view returns (uint256);
    function expectedReturn() external view returns (uint256);
}

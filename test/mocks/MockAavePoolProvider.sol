// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAavePoolProvider {
    address public immutable pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool() external view returns (address) {
        return pool;
    }
}
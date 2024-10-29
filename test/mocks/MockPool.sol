// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@aave/core-v3/contracts/protocol/pool/Pool.sol";
import "@aave/core-v3/contracts/protocol/configuration/PoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract MockPoolAddressesProvider is PoolAddressesProvider {
    constructor() PoolAddressesProvider("test_market", msg.sender) {}
}

contract MockPool is Pool {
    constructor(IPoolAddressesProvider provider) Pool(provider) {}

    receive() external payable {}
}

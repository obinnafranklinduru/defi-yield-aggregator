<!-- markdownlint-disable MD033 -->
<h1 align="center">Yield Aggregator Smart Contract (Hardhat Version)</h1>
<p align="center"><a href="https://github.com/obinnafranklinduru/defi-yield-aggregator-hardhat/">Check out the Hardhat Version</a></p>
<!-- markdownlint-enable MD033 -->

The **YieldAggregator** smart contract is designed to manage user deposits to maximize yield across popular DeFi protocols, such as **Aave** and **Compound**. The contract dynamically allocates funds to the protocol with the highest yield, provides fee management, and allows emergency withdrawals for enhanced security.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Contract Structure](#contract-structure)
- [Usage](#usage)
  - [Deployment](#deployment)
  - [Interacting with the Contract](#interacting-with-the-contract)
    - [Deposits](#deposits)
    - [Withdrawals](#withdrawals)
    - [Rebalance](#rebalance)
    - [Emergency Withdrawal](#emergency-withdrawal)
- [Roles and Permissions](#roles-and-permissions)
- [Fee Structure](#fee-structure)
- [Events](#events)
- [Security Considerations](#security-considerations)
- [Dependencies](#dependencies)
- [License](#license)

---

## Overview

**YieldAggregator** is a secure, flexible smart contract for managing user funds across DeFi protocols. It allows users to deposit **Wrapped ETH (WETH)**, dynamically shifting the funds between **Aave** and **Compound** to achieve optimal returns. The contract features management and performance fees, emergency withdrawal, and rebalance functionalities, all governed by the owner and assigned emergency admins.

## Features

- **Dynamic Yield Optimization**: Switches between Aave and Compound based on the higher APY.
- **Flexible Fee Structure**: Annual management and performance fees are applied and can be updated by the owner.
- **Emergency Controls**: Enables admins to manage emergency withdrawals and halt operations if necessary.
- **Automated Rebalance**: Adjusts fund allocation based on updated APY data.
- **Secure WETH Handling**: Utilizes SafeERC20 for safe WETH transfers.
- **Access Control**: Admin and owner roles for secure operation.

## Requirements

- **Solidity 0.8.26** or later
- **Node.js & npm** (for running tests and compiling)
- **OpenZeppelin** for access control, security, and token standards
- **Aave V3 and Compound Protocols** (integrated within the contract)

## Contract Structure

The contract is organized as follows:

1. **UserDeposit and Fees Structs**: Data structures to track user deposits and fee settings.
2. **Events**: Emitted for deposits, withdrawals, fee collection, and other key actions.
3. **Modifiers**: Access controls for emergency actions and emergency checks.
4. **Deposit and Withdraw Functions**: Main user-facing functions for depositing and withdrawing funds.
5. **Internal Protocol Management**: Functions for depositing, withdrawing, and rebalancing between protocols.
6. **Admin Functions**: For emergency actions and protocol configuration.

## Usage

### Deployment

1. **Prerequisites**: Deploy the contract with valid addresses for:

   - **WETH_ADDRESS**: WETH token address.
   - **AAVE_WETH_ADDRESS**: Address of Aave's WETH reserve.
   - **COMPOUND_PROXY_ADDRESS**: Compound protocol’s proxy contract.
   - **AAVE_POOL_PROVIDER**: Aave’s address provider for the pool.
   - **AAVE_POOL_ADDRESS**: A fallback address for Aave's lending pool
   - **feeCollector**: Address for collecting fees.

2. **Constructor Parameters**:
   - `_wethAddress`: Address of the WETH token.
   - `_aaveWethAddress`: Address of the Aave WETH reserve.
   - `_compoundProxy`: Address of the Compound proxy.
   - `_aavePoolProvider`: Address provider for Aave’s pool.
   - `_aavePoolAddress`: Fallback Address for Aave’s pool.
   - `_feeCollector`: Address for collecting protocol fees.

Example:

```solidity
YieldAggregator(
    _wethAddress,
    _aaveWethAddress,
    _compoundProxy,
    _aavePoolProvider,
    _aavePoolAddress,
    _feeCollector
)
```

### Interacting with the Contract

#### Deposits

**Function**: `deposit`

Deposits the user’s WETH into the yield aggregator, which allocates funds to the protocol offering the highest APY.

Parameters:

- `amount`: Amount of WETH to deposit.
- `compAPY`: Current APY from Compound.
- `aaveAPY`: Current APY from Aave.

Example Call:

```solidity
deposit(amount, compAPY, aaveAPY)
```

#### Withdrawals

**Function**: `withdraw`

Allows users to withdraw their deposited WETH along with any accrued yield, after fees.

Example Call:

```solidity
withdraw()
```

#### Rebalance

**Function**: `rebalance`

This function shifts funds from one protocol to another based on updated APY data. Only accessible by emergency admins and the owner.

Parameters:

- `compAPY`: Current APY from Compound.
- `aaveAPY`: Current APY from Aave.

Example Call:

```solidity
rebalance(compAPY, aaveAPY)
```

#### Emergency Withdrawal

**Function**: `emergencyWithdraw`

Allows emergency admins or the owner to withdraw all deposited funds to the owner’s address, effectively pausing the protocol and setting `emergencyExitEnabled` to true.

Example Call:

```solidity
emergencyWithdraw()
```

## Roles and Permissions

- **Owner**: Has full control, including configuration updates and fee adjustments.
- **Emergency Admins**: Assigned addresses authorized to perform emergency actions, such as calling `emergencyWithdraw` and `rebalance`.

## Fee Structure

The contract implements both management and performance fees:

- **Annual Management Fee**: Deducted based on the annual rate specified in basis points (1% by default).
- **Performance Fee**: Calculated on the yield accrued and also in basis points (10% by default).

Fees can be updated using the `updateProtocolConfiguration` function, but cannot exceed a set maximum:

- `MAX_MANAGEMENT_FEE`: 5% (500 basis points)
- `MAX_PERFORMANCE_FEE`: 30% (3000 basis points)

## Events

The contract emits several key events to notify external systems of state changes:

1. `Deposit`: Emitted on a successful deposit.
2. `Withdrawal`: Emitted upon a successful withdrawal.
3. `Rebalance`: Emitted when funds are rebalanced between protocols.
4. `EmergencyWithdrawal`: Emitted during an emergency withdrawal.
5. `FeesCollected`: Emitted when fees are collected.
6. `ProtocolConfigurationUpdated`: Emitted upon protocol configuration updates.

## Installation and Setup

1. **Clone Repository**:

   ```bash
   git clone https://github.com/obinnafranklinduru/defi-yield-aggregator.git
   cd defi-yield-aggregator
   ```

2. **Install Dependencies**:

   ```bash
   forge install
   ```

3. **Compile the Contract**:

   ```bash
   forge build
   ```

4. **Run Tests**:

   ```bash
   forge test -vvvv
   ```

5. **Deploy Contract**:
   Customize the deployment script as needed, then run:

   ```bash
   forge script script/YieldAggregator.s.sol --broadcast --rpc-url <network-url>
   ```

## Security Considerations

1. **Emergency Controls**: The contract includes emergency withdrawal functionality and only allows certain actions when `emergencyExitEnabled` is false.
2. **SafeERC20**: Uses SafeERC20 to manage WETH transfers, preventing potential token transfer errors.
3. **Custom Errors**: Uses custom error messages to minimize gas usage and improve debugging.
4. **Non-Reentrant**: All functions interacting with external contracts are protected by `nonReentrant`.
5. **Fallback and Receive Functions**: Fallback functions are set to revert on unexpected direct transfers.

## Dependencies

The contract relies on several external libraries and interfaces:

- **@openzeppelin/contracts/access/Ownable**: Provides ownership control.
- **@openzeppelin/contracts/utils/Pausable**: Allows the owner to pause functions.
- **@openzeppelin/contracts/token/ERC20/IERC20**: ERC20 token interface for WETH.
- **@openzeppelin/contracts/token/ERC20/utils/SafeERC20**: Ensures safe token transfers.
- **@aave/core-v3**: For interaction with Aave's Pool and PoolAddressesProvider.
- **Compound Protocol**: For interaction with Compound’s lending platform.

## License

This project is licensed under the [MIT License](https://github.com/obinnafranklinduru/defi-yield-aggregator/blob/main/LICENSE).

## Acknowledgments

This project was made possible by:

- [OpenZeppelin](https://openzeppelin.com) for their security libraries
- [Aave Protocol](https://aave.com) for yield generation
- [Compound Protocol](https://compound.finance) for lending and borrowing
- [Depth-Hoar Repo](https://github.com/Depth-Hoar/depth-yield-aggregator) for inspiration on getting started

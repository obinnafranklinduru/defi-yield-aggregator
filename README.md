# YieldAggregator Smart Contract

## Project Overview

`YieldAggregator` is a smart contract that maximizes yield on deposited Ethereum (WETH) by dynamically allocating funds between the Aave and Compound protocols based on the current APY (Annual Percentage Yield). The contract automates yield-optimization, collects performance and management fees, and includes emergency functions and rebalancing to ensure efficiency and security.

The contract is developed with Solidity on the Ethereum blockchain and leverages key DeFi protocols, making it suitable for users looking to maximize returns on their Ethereum holdings while benefiting from automated and efficient asset management.

## Features

- **Automated Yield Optimization**: Compares APY rates between Aave and Compound, reallocating funds based on the most favorable yield.
- **Rebalancing**: Reallocates funds only when there is a sufficient difference in APY rates between Aave and Compound, as determined by a configurable threshold.
- **Fee Collection**: Collects both a management fee and a performance fee, set as percentages in basis points (bps), to compensate for service usage.
- **Emergency Withdrawal**: Allows for emergency fund withdrawal in cases of contract compromise or protocol failure, accessible by authorized addresses.
- **Configurable Parameters**: Provides configurability of rebalancing thresholds, fees, and emergency admin access for better adaptability and management.

## Requirements

- **Solidity 0.8.26** or later
- **Node.js & npm** (for running tests and compiling)
- **OpenZeppelin** for access control, security, and token standards
- **Aave V3 and Compound Protocols** (integrated within the contract)

## Contract Overview

The core logic is contained in the `YieldAggregator` smart contract. Here is a breakdown of its functionality:

### Key Variables

- **AaveV3PoolAddressProvider, CompoundV3ProxyAddress, WETH_Address, AaaveWETH_Address**: Addresses for Aave and Compound contracts, as well as the WETH token.
- **depositAmount**: Tracks the amount deposited by users.
- **locationOfFunds**: Indicates the current protocol where funds are allocated (`Aave` or `Compound`).
- **rebalanceThreshold**: The minimum APY difference between Aave and Compound that triggers a reallocation.
- **managementFee, performanceFee**: Configurable fees that determine the management and performance compensation percentages.
- **emergencyExit, emergencyAdmins**: Emergency functions and access controls in case of a critical issue.

### Contract Functions

#### User Functions

- **deposit(\_amount, \_compAPY, \_aaveAPY)**:

  - Takes a user’s WETH deposit, checks the provided APYs for Compound and Aave, and allocates funds to the protocol offering the highest APY.
  - Rebalances funds if necessary based on the `rebalanceThreshold`.
  - Emits a `Deposit` event.

- **withdraw()**:

  - Withdraws all funds to the user. Before executing, it collects any outstanding management or performance fees.
  - Emits a `Withdraw` event.

- **rebalance(\_compAPY, \_aaveAPY)**:
  - Checks if a rebalance is necessary by comparing the APY difference to `rebalanceThreshold`. If met, reallocates funds to the protocol with the higher APY.
  - Can only be called by the owner and is subject to a cooldown to prevent excessive rebalancing.
  - Emits a `Rebalance` event.

#### Emergency Functions

- **emergencyWithdraw()**:
  - Allows withdrawal of funds bypassing normal checks, accessible only by the owner or an `emergencyAdmin`.
  - Sets `emergencyExit` to `true` and emits an `EmergencyWithdraw` event.

#### Fee Collection

- **\_collectManagementFee()**:

  - Calculates and collects the management fee, reducing `depositAmount` by the calculated fee amount.

- **\_collectPerformanceFee()**:
  - Calculates and collects performance fees on the yield generated beyond the original deposit, reducing `depositAmount` by the calculated fee amount.

#### Internal Protocol Functions

- **\_depositToAave(\_amount)**, **\_depositToCompound(\_amount)**:

  - Handle protocol-specific deposits for WETH into Aave and Compound.

- **\_withdrawFromAave()**, **\_withdrawFromCompound()**:
  - Withdraw funds from Aave and Compound, respectively, returning the amount withdrawn.

### Configurable Admin Functions

- **setRebalanceThreshold(\_newThreshold)**: Adjusts the minimum APY difference needed to trigger a rebalance.
- **setEmergencyAdmin(\_admin, \_status)**: Adds or removes addresses with `emergencyAdmin` permissions.
- **setPerformanceFee(\_newFee)**, **setManagementFee(\_newFee)**: Set or adjust the performance and management fees.

### Events

- **Deposit**: Triggered upon a successful deposit.
- **Withdraw**: Triggered upon a successful withdrawal.
- **Rebalance**: Triggered when a rebalance is performed.
- **EmergencyWithdraw**: Triggered when an emergency withdrawal is executed.
- **ManagementFeeCollected, PerformanceFeeCollected**: Triggered when management or performance fees are collected.

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
   forge test
   ```

5. **Deploy Contract**:
   Customize the deployment script as needed, then run:

   ```bash
   forge script script/YieldAggregator.s.sol --broadcast --rpc-url <network-url>
   ```

## Security Considerations

- **Emergency Exit**: Provides administrators with emergency withdrawal capabilities to secure funds if there’s a critical issue.
- **Reentrancy Guard**: Protects against reentrancy attacks on core functions.
- **Pausable Contract**: Allows contract pausing to temporarily suspend critical functions.
- **Access Control**: Only the owner or authorized emergency admins can execute certain sensitive functions.

## Future Enhancements

- **Additional Protocol Integrations**: Consider extending to other DeFi protocols like Yearn or Curve.
- **Dynamic Rebalance Thresholds**: Implement dynamic thresholds based on market conditions for more adaptive rebalancing.
- **Frontend Dashboard**: Develop a UI for users to monitor their deposits, yield, and contract status in real time.

## License

This project is licensed under the [MIT License](https://github.com/obinnafranklinduru/defi-yield-aggregator/blob/main/LICENSE).

## Acknowledgments

This project was made possible by:

- [OpenZeppelin](https://openzeppelin.com) for their security libraries
- [Aave Protocol](https://aave.com) for yield generation
- [Compound Protocol](https://compound.finance) for lending and borrowing
- [Depth-Hoar Repo](https://github.com/Depth-Hoar/depth-yield-aggregator) for inspiration on getting started

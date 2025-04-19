# sGHO - Savings GHO Vault

## About

sGHO is an [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) vault that allows users to earn yield on their GHO tokens. The vault is managed by the YieldMaestro contract, which handles yield distribution and rate management.

## Features

- **Full [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) compatibility.** sGHO implements all standard ERC4626 functions for deposits, withdrawals, and share calculations.
- **Automated yield distribution.** The YieldMaestro contract automatically calculates and distributes yield based on a configurable target rate.
- **Role-based access control.** The system uses Aave's ACLManager for managing permissions:
  - YIELD_MANAGER: Can set target rates and manage yield parameters
  - FUNDS_ADMIN: Can rescue tokens in case of emergencies
- **Permit support.** Users can approve sGHO to spend their GHO tokens using EIP-2612 permits, enabling gasless approvals.
- **Donation handling.** The vault can handle external GHO donations and transfer them to the YieldMaestro for yield distribution.

## Architecture

The system consists of two main contracts:

1. **sGHO.sol**: The main vault contract that:
   - Implements ERC4626 for standard vault operations
   - Handles deposits and withdrawals
   - Manages internal asset accounting
   - Integrates with YieldMaestro for yield distribution

2. **YieldMaestro.sol**: The yield management contract that:
   - Calculates and distributes yield based on target rates
   - Manages yield parameters and configurations
   - Handles emergency token rescues
   - Integrates with Aave's ACLManager for role management

## Yield Calculation

The yield is calculated using the following formula:
```solidity
unclaimedRewards = (vaultAssets * targetRate * elapsedTime) / (RATE_PRECISION * ONE_YEAR)
```

Where:
- `vaultAssets`: Total assets in the vault
- `targetRate`: Annual percentage rate in basis points (e.g., 1000 = 10%)
- `elapsedTime`: Time since last yield claim
- `RATE_PRECISION`: 1e10 for precise calculations
- `ONE_YEAR`: 365 days in seconds

## Security Considerations

The system implements several security measures:

- **Role-based access control** through Aave's ACLManager
- **Token rescue mechanism** for handling stuck tokens
- **Rate limiting** on yield claims (minimum 10 minutes between claims)
- **No ETH acceptance** to prevent accidental ETH deposits

## Limitations

- Yield claims are limited to once every 10 minutes to prevent excessive gas usage
- Target rates can only be modified by accounts with the YIELD_MANAGER role
- The system requires GHO tokens to be properly configured and accessible

## Security procedures

For this project, the security procedures applied/being finished are:

- Comprehensive test suite covering all vault operations
- Fuzzing tests for yield calculations and share conversions
- Integration tests with Aave's ACLManager
- Property-based testing for ERC4626 compliance

---

## Usage Examples

### Depositing GHO
```solidity
// Deposit GHO into the vault
sgho.deposit(amount, receiver);

// Deposit with permit (gasless approval)
sgho.permit(owner, spender, value, deadline, signature);
sgho.deposit(amount, receiver);
```

### Withdrawing GHO
```solidity
// Withdraw GHO from the vault
sgho.withdraw(assets, receiver, owner);

// Redeem shares for GHO
sgho.redeem(shares, receiver, owner);
```

### Managing Yield
```solidity
// Set target rate (YIELD_MANAGER only)
yieldMaestro.setTargetRate(1000); // 10% APR

// Preview claimable yield
uint256 claimable = yieldMaestro.previewClaimable();

// Claim yield (automatic on deposits/withdrawals)
yieldMaestro.claimSavings();
```

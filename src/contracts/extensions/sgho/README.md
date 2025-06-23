# sGHO - Savings GHO Vault

## About

sGHO is an [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) vault that allows users to earn yield on their GHO tokens. The vault automatically distributes yield to depositors through internal accounting, with a soft requirement for a buffer of GHO tokens to be maintained for yield distribution during full withdrawals.

## Features

- **Full [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) compatibility.** sGHO implements all standard ERC4626 functions for deposits, withdrawals, and share calculations.
- **Automatic yield distribution.** Yield is calculated and distributed internally during vault operations, eliminating the need for external yield claiming.

- **Role-based access control.** The system uses Aave's ACLManager for managing permissions:
  - YIELD_MANAGER: Can set target rates and manage yield parameters
  - FUNDS_ADMIN: Can rescue tokens in case of emergencies
- **Permit support.** Users can approve sGHO to spend their GHO tokens using EIP-2612 permits, enabling gasless approvals.
- **Donation handling.** The vault can handle external GHO donations and automatically incorporate them into the yield distribution system.

## Architecture

The system consists of a single main contract:

**sGHO.sol**: The main vault contract that:
- Implements ERC4626 for standard vault operations
- Handles deposits and withdrawals with automatic yield distribution
- Manages internal asset accounting with yield accrual
- Integrates with Aave's ACLManager for role management

## Inheritance and Dependencies

### sGHO.sol
- Inherits from:
  - `ERC4626` (OpenZeppelin) - For vault functionality
  - `ERC20Permit` (OpenZeppelin) - For permit functionality
  - `Initializable` (OpenZeppelin) - For initialization pattern
  - `IsGHO` (Custom interface) - Contract interface
- Uses OpenZeppelin interfaces:
  - `IERC20` - For token operations
  - `IAccessControl` - For role management
- Uses Aave libraries:
  - `WadRayMath` - For precise mathematical calculations

## Yield Calculation and Distribution

The yield is calculated and distributed automatically during vault operations:

```solidity
function _updateVault(uint256 assets, bool assetIncrease) internal {
  uint256 ratePerSecond = internalTotalAssets.wadMul(targetRate).wadDiv(ONE_YEAR);
  uint256 timeSinceLastUpdate = block.timestamp - lastUpdate;

  if (assetIncrease) {
    internalTotalAssets = timeSinceLastUpdate.wadMul(ratePerSecond) + assets;
  } else {
    internalTotalAssets = timeSinceLastUpdate.wadMul(ratePerSecond) - assets;
  }
}
```

### Key Components:
- **Target Rate**: Annual percentage rate in basis points (e.g., 1000 = 10%)
- **Internal Total Assets**: Tracks the vault's total assets including accrued yield
- **Yield Index**: Tracks the cumulative yield multiplier
- **Last Update**: Timestamp of the last vault update
- **GHO Buffer**: Optional GHO balance for smooth yield distribution

### Yield Distribution Process:
1. When deposits or withdrawals occur, `_updateVault()` is called
2. Yield is calculated based on elapsed time and current total assets
3. The internal total assets are updated to include accrued yield
4. A GHO buffer can be maintained to ensure smooth yield distribution during full withdrawals

## Security Considerations

The system implements several security measures:

- **Role-based access control** through Aave's ACLManager
- **Token rescue mechanism** for handling stuck tokens
- **No ETH acceptance** to prevent accidental ETH deposits
- **Optional GHO buffer** can be maintained for optimal yield distribution
- **Initialization pattern** prevents re-initialization attacks

## Limitations

- Target rates can only be modified by accounts with the YIELD_MANAGER role
- The system requires GHO tokens to be properly configured and accessible
- A GHO buffer is recommended but not required for optimal operation
- Yield is distributed automatically during vault operations, not on-demand

## Security Procedures

For this project, the security procedures applied/being finished are:

- Comprehensive test suite covering all vault operations
- Fuzzing tests for yield calculations and share conversions
- Integration tests with Aave's ACLManager
- Property-based testing for ERC4626 compliance
- Buffer requirement validation tests

---

## Usage Examples

### Depositing GHO
```solidity
// Deposit GHO into the vault
sgho.deposit(amount, receiver);

// Deposit with permit (gasless approval)
sgho.permit(owner, spender, value, deadline, signature);
sgho.deposit(amount, receiver);

// Mint shares for a specific amount of GHO
sgho.mint(shares, receiver);
```

### Withdrawing GHO
```solidity
// Withdraw GHO from the vault
sgho.withdraw(assets, receiver, owner);

// Redeem shares for GHO
sgho.redeem(shares, receiver, owner);
```

### Managing Yield and Configuration
```solidity
// Set target rate (YIELD_MANAGER only)
sgho.setTargetRate(1000); // 10% APR

// View current vault APR
uint256 apr = sgho.vaultAPR();

// Rescue tokens in emergency (FUNDS_ADMIN only)
sgho.rescueERC20(tokenAddress, recipient, amount);
```

### Permit Usage (Gasless Approvals)
```solidity
// Standard permit
sgho.permit(owner, spender, value, deadline, v, r, s);

// Custom permit with signature bytes
sgho.permit(owner, spender, value, deadline, signature);
```

## Important Notes

- **GHO Buffer**: A GHO buffer can be maintained to maintain full redeemability, but not mandatory for operations
- **Automatic Yield**: Yield is distributed automatically during deposit/withdrawal operations
- **No External Yield Management**: Unlike the previous version, there is no separate YieldMaestro contract
- **Simplified Architecture**: The system is now self-contained within the sGHO contract
- **Backwards Compatibility**: Previous IStakedToken compatibility has been removed for a cleaner implementation

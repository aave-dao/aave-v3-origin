```diff
diff --git a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol b/./downloads/SONIC/WALLET_BALANCE_PROVIDER.sol
index cc18346..e4cf53b 100644
--- a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol
+++ b/./downloads/SONIC/WALLET_BALANCE_PROVIDER.sol
@@ -1,7 +1,7 @@
-// SPDX-License-Identifier: MIT
+// SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,10 +221,14 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
-  struct ReserveData {
+  /**
+   * This exists specifically to maintain the `getReserveData()` interface, since the new, internal
+   * `ReserveData` struct includes the reserve's `virtualUnderlyingBalance`.
+   */
+  struct ReserveDataLegacy {
     //stores the reserve configuration
     ReserveConfigurationMap configuration;
     //the liquidity index. Expressed in ray
@@ -235,7 +239,7 @@ library DataTypes {
     uint128 variableBorrowIndex;
     //the current variable borrow rate. Expressed in ray
     uint128 currentVariableBorrowRate;
-    //the current stable borrow rate. Expressed in ray
+    // DEPRECATED on v3.2.0
     uint128 currentStableBorrowRate;
     //timestamp of last update
     uint40 lastUpdateTimestamp;
@@ -243,7 +247,7 @@ library DataTypes {
     uint16 id;
     //aToken address
     address aTokenAddress;
-    //stableDebtToken address
+    // DEPRECATED on v3.2.0
     address stableDebtTokenAddress;
     //variableDebtToken address
     address variableDebtTokenAddress;
@@ -257,6 +261,44 @@ library DataTypes {
     uint128 isolationModeTotalDebt;
   }
 
+  struct ReserveData {
+    //stores the reserve configuration
+    ReserveConfigurationMap configuration;
+    //the liquidity index. Expressed in ray
+    uint128 liquidityIndex;
+    //the current supply rate. Expressed in ray
+    uint128 currentLiquidityRate;
+    //variable borrow index. Expressed in ray
+    uint128 variableBorrowIndex;
+    //the current variable borrow rate. Expressed in ray
+    uint128 currentVariableBorrowRate;
+    /// @notice reused `__deprecatedStableBorrowRate` storage from pre 3.2
+    // the current accumulate deficit in underlying tokens
+    uint128 deficit;
+    //timestamp of last update
+    uint40 lastUpdateTimestamp;
+    //the id of the reserve. Represents the position in the list of the active reserves
+    uint16 id;
+    //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
+    uint40 liquidationGracePeriodUntil;
+    //aToken address
+    address aTokenAddress;
+    // DEPRECATED on v3.2.0
+    address __deprecatedStableDebtTokenAddress;
+    //variableDebtToken address
+    address variableDebtTokenAddress;
+    //address of the interest rate strategy
+    address interestRateStrategyAddress;
+    //the current treasury balance, scaled
+    uint128 accruedToTreasury;
+    //the outstanding unbacked aTokens minted through the bridging feature
+    uint128 unbacked;
+    //the outstanding debt borrowed against this asset in isolation mode
+    uint128 isolationModeTotalDebt;
+    //the amount of underlying accounted for by the protocol
+    uint128 virtualUnderlyingBalance;
+  }
+
   struct ReserveConfigurationMap {
     //bit 0-15: LTV
     //bit 16-31: Liq. threshold
@@ -265,19 +307,20 @@ library DataTypes {
     //bit 56: reserve is active
     //bit 57: reserve is frozen
     //bit 58: borrowing is enabled
-    //bit 59: stable rate borrowing enabled
+    //bit 59: DEPRECATED: stable rate borrowing enabled
     //bit 60: asset is paused
     //bit 61: borrowing in isolation mode is enabled
     //bit 62: siloed borrowing enabled
     //bit 63: flashloaning enabled
     //bit 64-79: reserve factor
-    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
-    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
-    //bit 152-167 liquidation protocol fee
-    //bit 168-175 eMode category
-    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
-    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
-    //bit 252-255 unused
+    //bit 80-115: borrow cap in whole tokens, borrowCap == 0 => no cap
+    //bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
+    //bit 152-167: liquidation protocol fee
+    //bit 168-175: DEPRECATED: eMode category
+    //bit 176-211: unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
+    //bit 212-251: debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
+    //bit 252: virtual accounting is enabled for the reserve
+    //bit 253-255 unused
 
     uint256 data;
   }
@@ -291,30 +334,49 @@ library DataTypes {
     uint256 data;
   }
 
-  struct EModeCategory {
+  // DEPRECATED: kept for backwards compatibility, might be removed in a future version
+  struct EModeCategoryLegacy {
     // each eMode category has a custom ltv and liquidation threshold
     uint16 ltv;
     uint16 liquidationThreshold;
     uint16 liquidationBonus;
-    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
+    // DEPRECATED
     address priceSource;
     string label;
   }
 
+  struct CollateralConfig {
+    uint16 ltv;
+    uint16 liquidationThreshold;
+    uint16 liquidationBonus;
+  }
+
+  struct EModeCategoryBaseConfiguration {
+    uint16 ltv;
+    uint16 liquidationThreshold;
+    uint16 liquidationBonus;
+    string label;
+  }
+
+  struct EModeCategory {
+    // each eMode category has a custom ltv and liquidation threshold
+    uint16 ltv;
+    uint16 liquidationThreshold;
+    uint16 liquidationBonus;
+    uint128 collateralBitmap;
+    string label;
+    uint128 borrowableBitmap;
+  }
+
   enum InterestRateMode {
     NONE,
-    STABLE,
+    __DEPRECATED,
     VARIABLE
   }
 
   struct ReserveCache {
     uint256 currScaledVariableDebt;
     uint256 nextScaledVariableDebt;
-    uint256 currPrincipalStableDebt;
-    uint256 currAvgStableBorrowRate;
-    uint256 currTotalStableDebt;
-    uint256 nextAvgStableBorrowRate;
-    uint256 nextTotalStableDebt;
     uint256 currLiquidityIndex;
     uint256 nextLiquidityIndex;
     uint256 currVariableBorrowIndex;
@@ -324,10 +386,8 @@ library DataTypes {
     uint256 reserveFactor;
     ReserveConfigurationMap reserveConfiguration;
     address aTokenAddress;
-    address stableDebtTokenAddress;
     address variableDebtTokenAddress;
     uint40 reserveLastUpdateTimestamp;
-    uint40 stableDebtLastUpdateTimestamp;
   }
 
   struct ExecuteLiquidationCallParams {
@@ -357,7 +417,6 @@ library DataTypes {
     InterestRateMode interestRateMode;
     uint16 referralCode;
     bool releaseUnderlying;
-    uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address oracle;
     uint8 userEModeCategory;
@@ -381,6 +440,11 @@ library DataTypes {
     uint8 userEModeCategory;
   }
 
+  struct ExecuteEliminateDeficitParams {
+    address asset;
+    uint256 amount;
+  }
+
   struct ExecuteSetUserEModeParams {
     uint256 reservesCount;
     address oracle;
@@ -409,9 +473,9 @@ library DataTypes {
     uint16 referralCode;
     uint256 flashLoanPremiumToProtocol;
     uint256 flashLoanPremiumTotal;
-    uint256 maxStableRateBorrowSizePercent;
     uint256 reservesCount;
     address addressesProvider;
+    address pool;
     uint8 userEModeCategory;
     bool isAuthorizedFlashBorrower;
   }
@@ -450,7 +514,6 @@ library DataTypes {
     address userAddress;
     uint256 amount;
     InterestRateMode interestRateMode;
-    uint256 maxStableLoanPercent;
     uint256 reservesCount;
     address oracle;
     uint8 userEModeCategory;
@@ -471,18 +534,16 @@ library DataTypes {
     uint256 unbacked;
     uint256 liquidityAdded;
     uint256 liquidityTaken;
-    uint256 totalStableDebt;
-    uint256 totalVariableDebt;
-    uint256 averageStableBorrowRate;
+    uint256 totalDebt;
     uint256 reserveFactor;
     address reserve;
-    address aToken;
+    bool usingVirtualBalance;
+    uint256 virtualUnderlyingBalance;
   }
 
   struct InitReserveParams {
     address asset;
     address aTokenAddress;
-    address stableDebtAddress;
     address variableDebtAddress;
     address interestRateStrategyAddress;
     uint16 reservesCount;
@@ -490,7 +551,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -528,17 +589,14 @@ library Errors {
   string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
   string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
   string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
-  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
   string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
   string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
   string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
   string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
   string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
   string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
-  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
   string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
   string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
-  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
   string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
   string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
   string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
@@ -551,7 +609,6 @@ library Errors {
   string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
   string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
   string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
-  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
   string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
   string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
   string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
@@ -580,17 +637,28 @@ library Errors {
   string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
   string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
   string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
-  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
   string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
   string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
   string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
-  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
   string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
   string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
   string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
+  string public constant INVALID_MAX_RATE = '92'; // The expect maximum borrow rate is invalid
+  string public constant WITHDRAW_TO_ATOKEN = '93'; // Withdrawing to the aToken is not allowed
+  string public constant SUPPLY_TO_ATOKEN = '94'; // Supplying to the aToken is not allowed
+  string public constant SLOPE_2_MUST_BE_GTE_SLOPE_1 = '95'; // Variable interest rate slope 2 can not be lower than slope 1
+  string public constant CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN = '96'; // 'The caller of the function is not a risk, pool or emergency admin'
+  string public constant LIQUIDATION_GRACE_SENTINEL_CHECK_FAILED = '97'; // 'Liquidation grace sentinel validation failed'
+  string public constant INVALID_GRACE_PERIOD = '98'; // Grace period above a valid range
+  string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
+  string public constant NOT_BORROWABLE_IN_EMODE = '100'; // Asset not borrowable in eMode
+  string public constant CALLER_NOT_UMBRELLA = '101'; // The caller of the function is not the umbrella contract
+  string public constant RESERVE_NOT_IN_DEFICIT = '102'; // The reserve is not in deficit
+  string public constant MUST_NOT_LEAVE_DUST = '103'; // Below a certain threshold liquidators need to take the full position
+  string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -666,7 +734,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -893,7 +961,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1006,7 +1074,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/interfaces/IPool.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1071,7 +1139,7 @@ interface IPool {
    * initiator of the transaction on flashLoan()
    * @param onBehalfOf The address that will be getting the debt
    * @param amount The amount borrowed out
-   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
+   * @param interestRateMode The rate mode: 2 for Variable, 1 is deprecated (changed on v3.2.0)
    * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
    * @param referralCode The referral code used
    */
@@ -1101,18 +1169,6 @@ interface IPool {
     bool useATokens
   );
 
-  /**
-   * @dev Emitted on swapBorrowRateMode()
-   * @param reserve The address of the underlying asset of the reserve
-   * @param user The address of the user swapping his rate mode
-   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
-   */
-  event SwapBorrowRateMode(
-    address indexed reserve,
-    address indexed user,
-    DataTypes.InterestRateMode interestRateMode
-  );
-
   /**
    * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
    * @param asset The address of the underlying asset of the reserve
@@ -1141,20 +1197,14 @@ interface IPool {
    */
   event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
 
-  /**
-   * @dev Emitted on rebalanceStableBorrowRate()
-   * @param reserve The address of the underlying asset of the reserve
-   * @param user The address of the user for which the rebalance has been executed
-   */
-  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
-
   /**
    * @dev Emitted on flashLoan()
    * @param target The address of the flash loan receiver contract
    * @param initiator The address initiating the flash loan
    * @param asset The address of the asset being flash borrowed
    * @param amount The amount flash borrowed
-   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
+   * @param interestRateMode The flashloan mode: 0 for regular flashloan,
+   *        1 for Stable (Deprecated on v3.2.0), 2 for Variable
    * @param premium The fee flash borrowed
    * @param referralCode The referral code used
    */
@@ -1193,7 +1243,7 @@ interface IPool {
    * @dev Emitted when the state of a reserve is updated.
    * @param reserve The address of the underlying asset of the reserve
    * @param liquidityRate The next liquidity rate
-   * @param stableBorrowRate The next stable borrow rate
+   * @param stableBorrowRate The next stable borrow rate @note deprecated on v3.2.0
    * @param variableBorrowRate The next variable borrow rate
    * @param liquidityIndex The next liquidity index
    * @param variableBorrowIndex The next variable borrow index
@@ -1207,6 +1257,14 @@ interface IPool {
     uint256 variableBorrowIndex
   );
 
+  /**
+   * @dev Emitted when the deficit of a reserve is covered.
+   * @param reserve The address of the underlying asset of the reserve
+   * @param caller The caller that triggered the DeficitCovered event
+   * @param amountCovered The amount of deficit covered
+   */
+  event DeficitCovered(address indexed reserve, address caller, uint256 amountCovered);
+
   /**
    * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
    * @param reserve The address of the reserve
@@ -1214,6 +1272,14 @@ interface IPool {
    */
   event MintedToTreasury(address indexed reserve, uint256 amountMinted);
 
+  /**
+   * @dev Emitted when deficit is realized on a liquidation.
+   * @param user The user address where the bad debt will be burned
+   * @param debtAsset The address of the underlying borrowed asset to be burned
+   * @param amountCreated The amount of deficit created
+   */
+  event DeficitCreated(address indexed user, address indexed debtAsset, uint256 amountCreated);
+
   /**
    * @notice Mints an `amount` of aTokens to the `onBehalfOf`
    * @param asset The address of the underlying asset to mint
@@ -1292,13 +1358,12 @@ interface IPool {
 
   /**
    * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
-   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
-   * corresponding debt token (StableDebtToken or VariableDebtToken)
+   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the VariableDebtToken
    * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
-   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
+   *   and 100 variable debt tokens
    * @param asset The address of the underlying asset to borrow
    * @param amount The amount to be borrowed
-   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
+   * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
    * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
@@ -1315,11 +1380,11 @@ interface IPool {
 
   /**
    * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
-   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
+   * - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `onBehalfOf` address
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
-   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
+   * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
    * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
    * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    * other borrower whose debt should be removed
@@ -1338,7 +1403,7 @@ interface IPool {
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
-   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
+   * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
    * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    * other borrower whose debt should be removed
@@ -1362,13 +1427,13 @@ interface IPool {
   /**
    * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
    * equivalent debt tokens
-   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
+   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable debt tokens
    * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
    * balance is not enough to cover the whole debt
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
-   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
+   * @param interestRateMode DEPRECATED in v3.2.0
    * @return The final amount repaid
    */
   function repayWithATokens(
@@ -1377,24 +1442,6 @@ interface IPool {
     uint256 interestRateMode
   ) external returns (uint256);
 
-  /**
-   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
-   * @param asset The address of the underlying asset borrowed
-   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
-   */
-  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;
-
-  /**
-   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
-   * - Users can be rebalanced if the following conditions are satisfied:
-   *     1. Usage ratio is above 95%
-   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
-   *        much has been borrowed at a stable rate and suppliers are not earning enough
-   * @param asset The address of the underlying asset borrowed
-   * @param user The address of the user to be rebalanced
-   */
-  function rebalanceStableBorrowRate(address asset, address user) external;
-
   /**
    * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
    * @param asset The address of the underlying asset supplied
@@ -1431,9 +1478,9 @@ interface IPool {
    * @param amounts The amounts of the assets being flash-borrowed
    * @param interestRateModes Types of the debt to open if the flash loan is not returned:
    *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
-   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
+   *   1 -> Deprecated on v3.2.0
    *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
-   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
+   * @param onBehalfOf The address  that will receive the debt in the case of using 2 on `modes`
    * @param params Variadic packed params to pass to the receiver as extra information
    * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
@@ -1498,14 +1545,12 @@ interface IPool {
    * @dev Only callable by the PoolConfigurator contract
    * @param asset The address of the underlying asset of the reserve
    * @param aTokenAddress The address of the aToken that will be assigned to the reserve
-   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
    * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
    * @param interestRateStrategyAddress The address of the interest rate strategy contract
    */
   function initReserve(
     address asset,
     address aTokenAddress,
-    address stableDebtAddress,
     address variableDebtAddress,
     address interestRateStrategyAddress
   ) external;
@@ -1513,6 +1558,7 @@ interface IPool {
   /**
    * @notice Drop a reserve
    * @dev Only callable by the PoolConfigurator contract
+   * @dev Does not reset eMode flags, which must be considered when reusing the same reserve id for a different reserve.
    * @param asset The address of the underlying asset of the reserve
    */
   function dropReserve(address asset) external;
@@ -1528,6 +1574,22 @@ interface IPool {
     address rateStrategyAddress
   ) external;
 
+  /**
+   * @notice Accumulates interest to all indexes of the reserve
+   * @dev Only callable by the PoolConfigurator contract
+   * @dev To be used when required by the configurator, for example when updating interest rates strategy data
+   * @param asset The address of the underlying asset of the reserve
+   */
+  function syncIndexesState(address asset) external;
+
+  /**
+   * @notice Updates interest rates on the reserve data
+   * @dev Only callable by the PoolConfigurator contract
+   * @dev To be used when required by the configurator, for example when updating interest rates strategy data
+   * @param asset The address of the underlying asset of the reserve
+   */
+  function syncRatesState(address asset) external;
+
   /**
    * @notice Sets the configuration bitmap of the reserve as a whole
    * @dev Only callable by the PoolConfigurator contract
@@ -1583,7 +1645,14 @@ interface IPool {
    * @param asset The address of the underlying asset of the reserve
    * @return The state and configuration data of the reserve
    */
-  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
+  function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory);
+
+  /**
+   * @notice Returns the virtual underlying balance of the reserve
+   * @param asset The address of the underlying asset of the reserve
+   * @return The reserve virtual underlying balance
+   */
+  function getVirtualUnderlyingBalance(address asset) external view returns (uint128);
 
   /**
    * @notice Validates and finalizes an aToken transfer
@@ -1611,6 +1680,13 @@ interface IPool {
    */
   function getReservesList() external view returns (address[] memory);
 
+  /**
+   * @notice Returns the number of initialized reserves
+   * @dev It includes dropped reserves
+   * @return The count
+   */
+  function getReservesCount() external view returns (uint256);
+
   /**
    * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
    * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
@@ -1646,20 +1722,70 @@ interface IPool {
   ) external;
 
   /**
-   * @notice Configures a new category for the eMode.
+   * @notice Configures a new or alters an existing collateral configuration of an eMode.
    * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
    * The category 0 is reserved as it's the default for volatile assets
    * @param id The id of the category
    * @param config The configuration of the category
    */
-  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;
+  function configureEModeCategory(
+    uint8 id,
+    DataTypes.EModeCategoryBaseConfiguration memory config
+  ) external;
+
+  /**
+   * @notice Replaces the current eMode collateralBitmap.
+   * @param id The id of the category
+   * @param collateralBitmap The collateralBitmap of the category
+   */
+  function configureEModeCategoryCollateralBitmap(uint8 id, uint128 collateralBitmap) external;
+
+  /**
+   * @notice Replaces the current eMode borrowableBitmap.
+   * @param id The id of the category
+   * @param borrowableBitmap The borrowableBitmap of the category
+   */
+  function configureEModeCategoryBorrowableBitmap(uint8 id, uint128 borrowableBitmap) external;
 
   /**
    * @notice Returns the data of an eMode category
+   * @dev DEPRECATED use independent getters instead
    * @param id The id of the category
    * @return The configuration data of the category
    */
-  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);
+  function getEModeCategoryData(
+    uint8 id
+  ) external view returns (DataTypes.EModeCategoryLegacy memory);
+
+  /**
+   * @notice Returns the label of an eMode category
+   * @param id The id of the category
+   * @return The label of the category
+   */
+  function getEModeCategoryLabel(uint8 id) external view returns (string memory);
+
+  /**
+   * @notice Returns the collateral config of an eMode category
+   * @param id The id of the category
+   * @return The ltv,lt,lb of the category
+   */
+  function getEModeCategoryCollateralConfig(
+    uint8 id
+  ) external view returns (DataTypes.CollateralConfig memory);
+
+  /**
+   * @notice Returns the collateralBitmap of an eMode category
+   * @param id The id of the category
+   * @return The collateralBitmap of the category
+   */
+  function getEModeCategoryCollateralBitmap(uint8 id) external view returns (uint128);
+
+  /**
+   * @notice Returns the borrowableBitmap of an eMode category
+   * @param id The id of the category
+   * @return The borrowableBitmap of the category
+   */
+  function getEModeCategoryBorrowableBitmap(uint8 id) external view returns (uint128);
 
   /**
    * @notice Allows a user to use the protocol in eMode
@@ -1682,10 +1808,20 @@ interface IPool {
   function resetIsolationModeTotalDebt(address asset) external;
 
   /**
-   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
-   * @return The percentage of available liquidity to borrow, expressed in bps
-   */
-  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);
+   * @notice Sets the liquidation grace period of the given asset
+   * @dev To enable a liquidation grace period, a timestamp in the future should be set,
+   *      To disable a liquidation grace period, any timestamp in the past works, like 0
+   * @param asset The address of the underlying asset to set the liquidationGracePeriod
+   * @param until Timestamp when the liquidation grace period will end
+   **/
+  function setLiquidationGracePeriod(address asset, uint40 until) external;
+
+  /**
+   * @notice Returns the liquidation grace period of the given asset
+   * @param asset The address of the underlying asset
+   * @return Timestamp when the liquidation grace period will end
+   **/
+  function getLiquidationGracePeriod(address asset) external view returns (uint40);
 
   /**
    * @notice Returns the total fee on flash loans
@@ -1738,9 +1874,75 @@ interface IPool {
    *   0 if the action is executed directly by the user, without any middle-man
    */
   function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
+
+  /**
+   * @notice It covers the deficit of a specified reserve by burning:
+   * - the equivalent aToken `amount` for assets with virtual accounting enabled
+   * - the equivalent `amount` of underlying for assets with virtual accounting disabled (e.g. GHO)
+   * @dev The deficit of a reserve can occur due to situations where borrowed assets are not repaid, leading to bad debt.
+   * @param asset The address of the underlying asset to cover the deficit.
+   * @param amount The amount to be covered, in aToken or underlying on non-virtual accounted assets
+   */
+  function eliminateReserveDeficit(address asset, uint256 amount) external;
+
+  /**
+   * @notice Returns the current deficit of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The current deficit of the reserve
+   */
+  function getReserveDeficit(address asset) external view returns (uint256);
+
+  /**
+   * @notice Returns the aToken address of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The address of the aToken
+   */
+  function getReserveAToken(address asset) external view returns (address);
+
+  /**
+   * @notice Returns the variableDebtToken address of a reserve.
+   * @param asset The address of the underlying asset of the reserve
+   * @return The address of the variableDebtToken
+   */
+  function getReserveVariableDebtToken(address asset) external view returns (address);
+
+  /**
+   * @notice Gets the address of the external FlashLoanLogic
+   */
+  function getFlashLoanLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external BorrowLogic
+   */
+  function getBorrowLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external BridgeLogic
+   */
+  function getBridgeLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external EModeLogic
+   */
+  function getEModeLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external LiquidationLogic
+   */
+  function getLiquidationLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external PoolLogic
+   */
+  function getPoolLogic() external view returns (address);
+
+  /**
+   * @notice Gets the address of the external SupplyLogic
+   */
+  function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -1748,25 +1950,26 @@ interface IPool {
  * @notice Implements the bitmap logic to handle the reserve configuration
  */
 library ReserveConfiguration {
-  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
-  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
-  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
-  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
-  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
+  uint256 internal constant LTV_MASK =                       0x000000000000000000000000000000000000000000000000000000000000FFFF; // prettier-ignore
+  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0x00000000000000000000000000000000000000000000000000000000FFFF0000; // prettier-ignore
+  uint256 internal constant LIQUIDATION_BONUS_MASK =         0x0000000000000000000000000000000000000000000000000000FFFF00000000; // prettier-ignore
+  uint256 internal constant DECIMALS_MASK =                  0x00000000000000000000000000000000000000000000000000FF000000000000; // prettier-ignore
+  uint256 internal constant ACTIVE_MASK =                    0x0000000000000000000000000000000000000000000000000100000000000000; // prettier-ignore
+  uint256 internal constant FROZEN_MASK =                    0x0000000000000000000000000000000000000000000000000200000000000000; // prettier-ignore
+  uint256 internal constant BORROWING_MASK =                 0x0000000000000000000000000000000000000000000000000400000000000000; // prettier-ignore
+  // @notice there is an unoccupied hole of 1 bit at position 59 from pre 3.2 stableBorrowRateEnabled
+  uint256 internal constant PAUSED_MASK =                    0x0000000000000000000000000000000000000000000000001000000000000000; // prettier-ignore
+  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0x0000000000000000000000000000000000000000000000002000000000000000; // prettier-ignore
+  uint256 internal constant SILOED_BORROWING_MASK =          0x0000000000000000000000000000000000000000000000004000000000000000; // prettier-ignore
+  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0x0000000000000000000000000000000000000000000000008000000000000000; // prettier-ignore
+  uint256 internal constant RESERVE_FACTOR_MASK =            0x00000000000000000000000000000000000000000000FFFF0000000000000000; // prettier-ignore
+  uint256 internal constant BORROW_CAP_MASK =                0x00000000000000000000000000000000000FFFFFFFFF00000000000000000000; // prettier-ignore
+  uint256 internal constant SUPPLY_CAP_MASK =                0x00000000000000000000000000FFFFFFFFF00000000000000000000000000000; // prettier-ignore
+  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0x0000000000000000000000FFFF00000000000000000000000000000000000000; // prettier-ignore
+  //@notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
+  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0x00000000000FFFFFFFFF00000000000000000000000000000000000000000000; // prettier-ignore
+  uint256 internal constant DEBT_CEILING_MASK =              0x0FFFFFFFFFF00000000000000000000000000000000000000000000000000000; // prettier-ignore
+  uint256 internal constant VIRTUAL_ACC_ACTIVE_MASK =        0x1000000000000000000000000000000000000000000000000000000000000000; // prettier-ignore
 
   /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
   uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
@@ -1775,7 +1978,6 @@ library ReserveConfiguration {
   uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
   uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
   uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
-  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
   uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
   uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
   uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
@@ -1784,9 +1986,10 @@ library ReserveConfiguration {
   uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
   uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
   uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
-  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
+  //@notice there is an unoccupied hole of 8 bits from 168 to 176 left from pre 3.2 eModeCategory
   uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
   uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;
+  uint256 internal constant VIRTUAL_ACC_START_BIT_POSITION = 252;
 
   uint256 internal constant MAX_VALID_LTV = 65535;
   uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
@@ -1796,7 +1999,6 @@ library ReserveConfiguration {
   uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
   uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
   uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
-  uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
   uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
   uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;
 
@@ -1811,7 +2013,7 @@ library ReserveConfiguration {
   function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
     require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);
 
-    self.data = (self.data & LTV_MASK) | ltv;
+    self.data = (self.data & ~LTV_MASK) | ltv;
   }
 
   /**
@@ -1820,7 +2022,7 @@ library ReserveConfiguration {
    * @return The loan to value
    */
   function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
-    return self.data & ~LTV_MASK;
+    return self.data & LTV_MASK;
   }
 
   /**
@@ -1835,7 +2037,7 @@ library ReserveConfiguration {
     require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);
 
     self.data =
-      (self.data & LIQUIDATION_THRESHOLD_MASK) |
+      (self.data & ~LIQUIDATION_THRESHOLD_MASK) |
       (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
   }
 
@@ -1847,7 +2049,7 @@ library ReserveConfiguration {
   function getLiquidationThreshold(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
   }
 
   /**
@@ -1862,7 +2064,7 @@ library ReserveConfiguration {
     require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);
 
     self.data =
-      (self.data & LIQUIDATION_BONUS_MASK) |
+      (self.data & ~LIQUIDATION_BONUS_MASK) |
       (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
   }
 
@@ -1874,7 +2076,7 @@ library ReserveConfiguration {
   function getLiquidationBonus(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
+    return (self.data & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
   }
 
   /**
@@ -1888,7 +2090,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);
 
-    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
+    self.data = (self.data & ~DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
   }
 
   /**
@@ -1899,7 +2101,7 @@ library ReserveConfiguration {
   function getDecimals(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
+    return (self.data & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
   }
 
   /**
@@ -1909,7 +2111,7 @@ library ReserveConfiguration {
    */
   function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
     self.data =
-      (self.data & ACTIVE_MASK) |
+      (self.data & ~ACTIVE_MASK) |
       (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
   }
 
@@ -1919,7 +2121,7 @@ library ReserveConfiguration {
    * @return The active state
    */
   function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~ACTIVE_MASK) != 0;
+    return (self.data & ACTIVE_MASK) != 0;
   }
 
   /**
@@ -1929,7 +2131,7 @@ library ReserveConfiguration {
    */
   function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
     self.data =
-      (self.data & FROZEN_MASK) |
+      (self.data & ~FROZEN_MASK) |
       (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
   }
 
@@ -1939,7 +2141,7 @@ library ReserveConfiguration {
    * @return The frozen state
    */
   function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~FROZEN_MASK) != 0;
+    return (self.data & FROZEN_MASK) != 0;
   }
 
   /**
@@ -1949,7 +2151,7 @@ library ReserveConfiguration {
    */
   function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
     self.data =
-      (self.data & PAUSED_MASK) |
+      (self.data & ~PAUSED_MASK) |
       (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
   }
 
@@ -1959,7 +2161,7 @@ library ReserveConfiguration {
    * @return The paused state
    */
   function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
-    return (self.data & ~PAUSED_MASK) != 0;
+    return (self.data & PAUSED_MASK) != 0;
   }
 
   /**
@@ -1976,7 +2178,7 @@ library ReserveConfiguration {
     bool borrowable
   ) internal pure {
     self.data =
-      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
+      (self.data & ~BORROWABLE_IN_ISOLATION_MASK) |
       (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
   }
 
@@ -1992,7 +2194,7 @@ library ReserveConfiguration {
   function getBorrowableInIsolation(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
+    return (self.data & BORROWABLE_IN_ISOLATION_MASK) != 0;
   }
 
   /**
@@ -2006,7 +2208,7 @@ library ReserveConfiguration {
     bool siloed
   ) internal pure {
     self.data =
-      (self.data & SILOED_BORROWING_MASK) |
+      (self.data & ~SILOED_BORROWING_MASK) |
       (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
   }
 
@@ -2019,7 +2221,7 @@ library ReserveConfiguration {
   function getSiloedBorrowing(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~SILOED_BORROWING_MASK) != 0;
+    return (self.data & SILOED_BORROWING_MASK) != 0;
   }
 
   /**
@@ -2032,7 +2234,7 @@ library ReserveConfiguration {
     bool enabled
   ) internal pure {
     self.data =
-      (self.data & BORROWING_MASK) |
+      (self.data & ~BORROWING_MASK) |
       (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
   }
 
@@ -2044,32 +2246,7 @@ library ReserveConfiguration {
   function getBorrowingEnabled(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~BORROWING_MASK) != 0;
-  }
-
-  /**
-   * @notice Enables or disables stable rate borrowing on the reserve
-   * @param self The reserve configuration
-   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
-   */
-  function setStableRateBorrowingEnabled(
-    DataTypes.ReserveConfigurationMap memory self,
-    bool enabled
-  ) internal pure {
-    self.data =
-      (self.data & STABLE_BORROWING_MASK) |
-      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
-  }
-
-  /**
-   * @notice Gets the stable rate borrowing state of the reserve
-   * @param self The reserve configuration
-   * @return The stable rate borrowing state
-   */
-  function getStableRateBorrowingEnabled(
-    DataTypes.ReserveConfigurationMap memory self
-  ) internal pure returns (bool) {
-    return (self.data & ~STABLE_BORROWING_MASK) != 0;
+    return (self.data & BORROWING_MASK) != 0;
   }
 
   /**
@@ -2084,7 +2261,7 @@ library ReserveConfiguration {
     require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);
 
     self.data =
-      (self.data & RESERVE_FACTOR_MASK) |
+      (self.data & ~RESERVE_FACTOR_MASK) |
       (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
   }
 
@@ -2096,7 +2273,7 @@ library ReserveConfiguration {
   function getReserveFactor(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
+    return (self.data & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
   }
 
   /**
@@ -2110,7 +2287,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);
 
-    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2121,7 +2298,7 @@ library ReserveConfiguration {
   function getBorrowCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
+    return (self.data & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2135,7 +2312,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);
 
-    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
+    self.data = (self.data & ~SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
   }
 
   /**
@@ -2146,7 +2323,7 @@ library ReserveConfiguration {
   function getSupplyCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
+    return (self.data & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
   }
 
   /**
@@ -2160,7 +2337,7 @@ library ReserveConfiguration {
   ) internal pure {
     require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);
 
-    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
+    self.data = (self.data & ~DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
   }
 
   /**
@@ -2171,7 +2348,7 @@ library ReserveConfiguration {
   function getDebtCeiling(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
+    return (self.data & DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
   }
 
   /**
@@ -2189,7 +2366,7 @@ library ReserveConfiguration {
     );
 
     self.data =
-      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
+      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) |
       (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
   }
 
@@ -2202,7 +2379,7 @@ library ReserveConfiguration {
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
     return
-      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
+      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
   }
 
   /**
@@ -2217,7 +2394,7 @@ library ReserveConfiguration {
     require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);
 
     self.data =
-      (self.data & UNBACKED_MINT_CAP_MASK) |
+      (self.data & ~UNBACKED_MINT_CAP_MASK) |
       (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
   }
 
@@ -2229,57 +2406,62 @@ library ReserveConfiguration {
   function getUnbackedMintCap(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (uint256) {
-    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
+    return (self.data & UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
   }
 
   /**
-   * @notice Sets the eMode asset category
+   * @notice Sets the flashloanable flag for the reserve
    * @param self The reserve configuration
-   * @param category The asset category when the user selects the eMode
+   * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
    */
-  function setEModeCategory(
+  function setFlashLoanEnabled(
     DataTypes.ReserveConfigurationMap memory self,
-    uint256 category
+    bool flashLoanEnabled
   ) internal pure {
-    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.INVALID_EMODE_CATEGORY);
-
-    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
+    self.data =
+      (self.data & ~FLASHLOAN_ENABLED_MASK) |
+      (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
   }
 
   /**
-   * @dev Gets the eMode asset category
+   * @notice Gets the flashloanable flag for the reserve
    * @param self The reserve configuration
-   * @return The eMode category for the asset
+   * @return The flashloanable flag
    */
-  function getEModeCategory(
+  function getFlashLoanEnabled(
     DataTypes.ReserveConfigurationMap memory self
-  ) internal pure returns (uint256) {
-    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
+  ) internal pure returns (bool) {
+    return (self.data & FLASHLOAN_ENABLED_MASK) != 0;
   }
 
   /**
-   * @notice Sets the flashloanable flag for the reserve
+   * @notice Sets the virtual account active/not state of the reserve
    * @param self The reserve configuration
-   * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
+   * @param active The active state
    */
-  function setFlashLoanEnabled(
+  function setVirtualAccActive(
     DataTypes.ReserveConfigurationMap memory self,
-    bool flashLoanEnabled
+    bool active
   ) internal pure {
     self.data =
-      (self.data & FLASHLOAN_ENABLED_MASK) |
-      (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
+      (self.data & ~VIRTUAL_ACC_ACTIVE_MASK) |
+      (uint256(active ? 1 : 0) << VIRTUAL_ACC_START_BIT_POSITION);
   }
 
   /**
-   * @notice Gets the flashloanable flag for the reserve
+   * @notice Gets the virtual account active/not state of the reserve
+   * @dev The state should be true for all normal assets and should be false
+   * Virtual accounting being disabled means that the asset:
+   * - is GHO
+   * - can never be supplied
+   * - the interest rate strategy is not influenced by the virtual balance
    * @param self The reserve configuration
-   * @return The flashloanable flag
+   * @return The active state
    */
-  function getFlashLoanEnabled(
+  function getIsVirtualAccActive(
     DataTypes.ReserveConfigurationMap memory self
   ) internal pure returns (bool) {
-    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
+    return (self.data & VIRTUAL_ACC_ACTIVE_MASK) != 0;
   }
 
   /**
@@ -2288,20 +2470,18 @@ library ReserveConfiguration {
    * @return The state flag representing active
    * @return The state flag representing frozen
    * @return The state flag representing borrowing enabled
-   * @return The state flag representing stableRateBorrowing enabled
    * @return The state flag representing paused
    */
   function getFlags(
     DataTypes.ReserveConfigurationMap memory self
-  ) internal pure returns (bool, bool, bool, bool, bool) {
+  ) internal pure returns (bool, bool, bool, bool) {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~ACTIVE_MASK) != 0,
-      (dataLocal & ~FROZEN_MASK) != 0,
-      (dataLocal & ~BORROWING_MASK) != 0,
-      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
-      (dataLocal & ~PAUSED_MASK) != 0
+      (dataLocal & ACTIVE_MASK) != 0,
+      (dataLocal & FROZEN_MASK) != 0,
+      (dataLocal & BORROWING_MASK) != 0,
+      (dataLocal & PAUSED_MASK) != 0
     );
   }
 
@@ -2313,20 +2493,18 @@ library ReserveConfiguration {
    * @return The state param representing liquidation bonus
    * @return The state param representing reserve decimals
    * @return The state param representing reserve factor
-   * @return The state param representing eMode category
    */
   function getParams(
     DataTypes.ReserveConfigurationMap memory self
-  ) internal pure returns (uint256, uint256, uint256, uint256, uint256, uint256) {
+  ) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
     uint256 dataLocal = self.data;
 
     return (
-      dataLocal & ~LTV_MASK,
-      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
-      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
-      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
-      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
-      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
+      dataLocal & LTV_MASK,
+      (dataLocal & LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
+      (dataLocal & LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
+      (dataLocal & DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
+      (dataLocal & RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
     );
   }
 
@@ -2342,13 +2520,13 @@ library ReserveConfiguration {
     uint256 dataLocal = self.data;
 
     return (
-      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
-      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
+      (dataLocal & BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
+      (dataLocal & SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
     );
   }
 }
 
-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol
 
 /**
  * @title WalletBalanceProvider contract
@@ -2433,7 +2611,7 @@ contract WalletBalanceProvider {
         reservesWithEth[j]
       );
 
-      (bool isActive, , , , ) = configuration.getFlags();
+      (bool isActive, , , ) = configuration.getFlags();
 
       if (!isActive) {
         balances[j] = 0;
```

```diff
diff --git a/./downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol b/./downloads/SONIC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol
index aa145c3..7db9e11 100644
--- a/./downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol
+++ b/./downloads/SONIC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol

-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/SONIC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol

 /**
  * @title IncentivizedERC20
@@ -2512,8 +2714,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   /**
    * @dev UserState - additionalData is a flexible field.
    * ATokens and VariableDebtTokens use this field store the index of the
-   * user's last supply/withdrawal/borrow/repayment. StableDebtTokens use
-   * this field to store the user's stable rate.
+   * user's last supply/withdrawal/borrow/repayment.
    */
   struct UserState {
     uint128 balance;
@@ -2536,15 +2737,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   /**
    * @dev Constructor.
    * @param pool The reference to the main Pool contract
-   * @param name The name of the token
-   * @param symbol The symbol of the token
-   * @param decimals The number of decimals of the token
+   * @param name_ The name of the token
+   * @param symbol_ The symbol of the token
+   * @param decimals_ The number of decimals of the token
    */
-  constructor(IPool pool, string memory name, string memory symbol, uint8 decimals) {
+  constructor(IPool pool, string memory name_, string memory symbol_, uint8 decimals_) {
     _addressesProvider = pool.ADDRESSES_PROVIDER();
-    _name = name;
-    _symbol = symbol;
-    _decimals = decimals;
+    _name = name_;
+    _symbol = symbol_;
+    _decimals = decimals_;
     POOL = pool;
   }

@@ -2705,7 +2906,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }

-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/VariableDebtToken.sol
+// downloads/SONIC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/contracts/protocol/tokenization/VariableDebtToken.sol

 /**
  * @title VariableDebtToken
@@ -2925,12 +3126,10 @@ abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBa
  * at variable rate mode
  * @dev Transfer and approve functionalities are disabled since its a non-transferable token
  */
-contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
+abstract contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
   using WadRayMath for uint256;
   using SafeCast for uint256;

-  uint256 public constant DEBT_TOKEN_REVISION = 0x1;
-
   /**
    * @dev Constructor.
    * @param pool The address of the Pool contract
@@ -2953,32 +3152,7 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
     string memory debtTokenName,
     string memory debtTokenSymbol,
     bytes calldata params
-  ) external override initializer {
-    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
-    _setName(debtTokenName);
-    _setSymbol(debtTokenSymbol);
-    _setDecimals(debtTokenDecimals);
-
-    _underlyingAsset = underlyingAsset;
-    _incentivesController = incentivesController;
-
-    _domainSeparator = _calculateDomainSeparator();
-
-    emit Initialized(
-      underlyingAsset,
-      address(POOL),
-      address(incentivesController),
-      debtTokenDecimals,
-      debtTokenName,
-      debtTokenSymbol,
-      params
-    );
-  }
-
-  /// @inheritdoc VersionedInitializable
-  function getRevision() internal pure virtual override returns (uint256) {
-    return DEBT_TOKEN_REVISION;
-  }
+  ) external virtual;

   /// @inheritdoc IERC20
   function balanceOf(address user) public view virtual override returns (uint256) {
@@ -3057,3 +3231,47 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
     return _underlyingAsset;
   }
 }
+
+// downloads/SONIC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/contracts/instances/VariableDebtTokenInstance.sol
+
+contract VariableDebtTokenInstance is VariableDebtToken {
+  uint256 public constant DEBT_TOKEN_REVISION = 1;
+
+  constructor(IPool pool) VariableDebtToken(pool) {}
+
+  /// @inheritdoc VersionedInitializable
+  function getRevision() internal pure virtual override returns (uint256) {
+    return DEBT_TOKEN_REVISION;
+  }
+
+  /// @inheritdoc IInitializableDebtToken
+  function initialize(
+    IPool initializingPool,
+    address underlyingAsset,
+    IAaveIncentivesController incentivesController,
+    uint8 debtTokenDecimals,
+    string memory debtTokenName,
+    string memory debtTokenSymbol,
+    bytes calldata params
+  ) external override initializer {
+    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
+    _setName(debtTokenName);
+    _setSymbol(debtTokenSymbol);
+    _setDecimals(debtTokenDecimals);
+
+    _underlyingAsset = underlyingAsset;
+    _incentivesController = incentivesController;
+
+    _domainSeparator = _calculateDomainSeparator();
+
+    emit Initialized(
+      underlyingAsset,
+      address(POOL),
+      address(incentivesController),
+      debtTokenDecimals,
+      debtTokenName,
+      debtTokenSymbol,
+      params
+    );
+  }
+}
```

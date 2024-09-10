```diff
diff --git a/./downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL.sol

-// downloads/GNOSIS/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtToken/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol

 /**
  * @title IncentivizedERC20
@@ -2536,15 +2686,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
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

@@ -2705,7 +2855,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }

-contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
+abstract contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
   using WadRayMath for uint256;
   using SafeCast for uint256;

-  uint256 public constant DEBT_TOKEN_REVISION = 0x1;
-
   /**
    * @dev Constructor.
    * @param pool The address of the Pool contract
@@ -2953,32 +3101,7 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
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
@@ -3057,3 +3180,47 @@ contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDe
     return _underlyingAsset;
   }
 }
+
+// downloads/ZKSYNC/DEFAULT_VARIABLE_DEBT_TOKEN_IMPL/VariableDebtTokenInstance/src/core/instances/VariableDebtTokenInstance.sol
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

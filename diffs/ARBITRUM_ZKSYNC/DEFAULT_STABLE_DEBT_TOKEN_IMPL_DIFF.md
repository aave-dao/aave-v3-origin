```diff
diff --git a/./downloads/ARBITRUM/DEFAULT_STABLE_DEBT_TOKEN_IMPL.sol b/./downloads/ZKSYNC/DEFAULT_STABLE_DEBT_TOKEN_IMPL.sol
index a475dde..35e192c 100644
--- a/./downloads/ARBITRUM/DEFAULT_STABLE_DEBT_TOKEN_IMPL.sol
+++ b/./downloads/ZKSYNC/DEFAULT_STABLE_DEBT_TOKEN_IMPL.sol

-// downloads/ARBITRUM/DEFAULT_STABLE_DEBT_TOKEN_IMPL/StableDebtToken/src/v3ArbStableDebtToken/StableDebtToken/lib/aave-v3-core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/ZKSYNC/DEFAULT_STABLE_DEBT_TOKEN_IMPL/StableDebtTokenInstance/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol

 /**
  * @title IncentivizedERC20
@@ -2654,15 +2708,15 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
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

@@ -2823,7 +2877,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }

-// downloads/ARBITRUM/DEFAULT_STABLE_DEBT_TOKEN_IMPL/StableDebtToken/src/v3ArbStableDebtToken/StableDebtToken/lib/aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol
+// downloads/ZKSYNC/DEFAULT_STABLE_DEBT_TOKEN_IMPL/StableDebtTokenInstance/src/core/contracts/protocol/tokenization/StableDebtToken.sol

 /**
  * @title StableDebtToken
@@ -2832,20 +2886,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
  * at stable rate mode
  * @dev Transfer and approve functionalities are disabled since its a non-transferable token
  */
-contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
-  using WadRayMath for uint256;
-  using SafeCast for uint256;
-
-  uint256 public constant DEBT_TOKEN_REVISION = 0x3;
-
-  // Map of users address and the timestamp of their last update (userAddress => lastUpdateTimestamp)
-  mapping(address => uint40) internal _timestamps;
-
-  uint128 internal _avgStableRate;
-
-  // Timestamp of the last update of the total supply
-  uint40 internal _totalSupplyTimestamp;
-
+abstract contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
   /**
    * @dev Constructor.
    * @param pool The address of the Pool contract
@@ -2865,195 +2906,66 @@ contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
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

   /// @inheritdoc IStableDebtToken
-  function getAverageStableRate() external view virtual override returns (uint256) {
-    return _avgStableRate;
+  function getAverageStableRate() external pure virtual override returns (uint256) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
-  function getUserLastUpdated(address user) external view virtual override returns (uint40) {
-    return _timestamps[user];
+  function getUserLastUpdated(address) external pure virtual override returns (uint40) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
-  function getUserStableRate(address user) external view virtual override returns (uint256) {
-    return _userState[user].additionalData;
+  function getUserStableRate(address) external pure virtual override returns (uint256) {
+    return 0;
   }

   /// @inheritdoc IERC20
-  function balanceOf(address account) public view virtual override returns (uint256) {
-    uint256 accountBalance = super.balanceOf(account);
-    uint256 stableRate = _userState[account].additionalData;
-    if (accountBalance == 0) {
-      return 0;
-    }
-    uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
-      stableRate,
-      _timestamps[account]
-    );
-    return accountBalance.rayMul(cumulatedInterest);
+  function balanceOf(address) public pure virtual override returns (uint256) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
-  /**
-   * @dev DEPRECATED, no stable debt should be minted in any operation
-   **/
   function mint(
     address,
     address,
     uint256,
     uint256
   ) external virtual override onlyPool returns (bool, uint256, uint256) {
-    revert('STABLE_BORROWING_DEPRECATED');
+    revert(Errors.OPERATION_NOT_SUPPORTED);
   }

   /// @inheritdoc IStableDebtToken
-  function burn(
-    address from,
-    uint256 amount
-  ) external virtual override onlyPool returns (uint256, uint256) {
-    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(from);
-
-    uint256 previousSupply = totalSupply();
-    uint256 nextAvgStableRate = 0;
-    uint256 nextSupply = 0;
-    uint256 userStableRate = _userState[from].additionalData;
-
-    // Since the total supply and each single user debt accrue separately,
-    // there might be accumulation errors so that the last borrower repaying
-    // might actually try to repay more than the available debt supply.
-    // In this case we simply set the total supply and the avg stable rate to 0
-    if (previousSupply <= amount) {
-      _avgStableRate = 0;
-      _totalSupply = 0;
-    } else {
-      nextSupply = _totalSupply = previousSupply - amount;
-      uint256 firstTerm = uint256(_avgStableRate).rayMul(previousSupply.wadToRay());
-      uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());
-
-      // For the same reason described above, when the last user is repaying it might
-      // happen that user rate * user balance > avg rate * total supply. In that case,
-      // we simply set the avg rate to 0
-      if (secondTerm >= firstTerm) {
-        nextAvgStableRate = _totalSupply = _avgStableRate = 0;
-      } else {
-        nextAvgStableRate = _avgStableRate = (
-          (firstTerm - secondTerm).rayDiv(nextSupply.wadToRay())
-        ).toUint128();
-      }
-    }
-
-    if (amount == currentBalance) {
-      _userState[from].additionalData = 0;
-      _timestamps[from] = 0;
-    } else {
-      //solium-disable-next-line
-      _timestamps[from] = uint40(block.timestamp);
-    }
-    //solium-disable-next-line
-    _totalSupplyTimestamp = uint40(block.timestamp);
-
-    if (balanceIncrease > amount) {
-      uint256 amountToMint = balanceIncrease - amount;
-      _mint(from, amountToMint, previousSupply);
-      emit Transfer(address(0), from, amountToMint);
-      emit Mint(
-        from,
-        from,
-        amountToMint,
-        currentBalance,
-        balanceIncrease,
-        userStableRate,
-        nextAvgStableRate,
-        nextSupply
-      );
-    } else {
-      uint256 amountToBurn = amount - balanceIncrease;
-      _burn(from, amountToBurn, previousSupply);
-      emit Transfer(from, address(0), amountToBurn);
-      emit Burn(from, amountToBurn, currentBalance, balanceIncrease, nextAvgStableRate, nextSupply);
-    }
-
-    return (nextSupply, nextAvgStableRate);
-  }
-
-  /**
-   * @notice Calculates the increase in balance since the last user interaction
-   * @param user The address of the user for which the interest is being accumulated
-   * @return The previous principal balance
-   * @return The new principal balance
-   * @return The balance increase
-   */
-  function _calculateBalanceIncrease(
-    address user
-  ) internal view returns (uint256, uint256, uint256) {
-    uint256 previousPrincipalBalance = super.balanceOf(user);
-
-    if (previousPrincipalBalance == 0) {
-      return (0, 0, 0);
-    }
-
-    uint256 newPrincipalBalance = balanceOf(user);
-
-    return (
-      previousPrincipalBalance,
-      newPrincipalBalance,
-      newPrincipalBalance - previousPrincipalBalance
-    );
+  function burn(address, uint256) external virtual override onlyPool returns (uint256, uint256) {
+    revert(Errors.OPERATION_NOT_SUPPORTED);
   }

   /// @inheritdoc IStableDebtToken
-  function getSupplyData() external view override returns (uint256, uint256, uint256, uint40) {
-    uint256 avgRate = _avgStableRate;
-    return (super.totalSupply(), _calcTotalSupply(avgRate), avgRate, _totalSupplyTimestamp);
+  function getSupplyData() external pure override returns (uint256, uint256, uint256, uint40) {
+    return (0, 0, 0, 0);
   }

   /// @inheritdoc IStableDebtToken
-  function getTotalSupplyAndAvgRate() external view override returns (uint256, uint256) {
-    uint256 avgRate = _avgStableRate;
-    return (_calcTotalSupply(avgRate), avgRate);
+  function getTotalSupplyAndAvgRate() external pure override returns (uint256, uint256) {
+    return (0, 0);
   }

   /// @inheritdoc IERC20
-  function totalSupply() public view virtual override returns (uint256) {
-    return _calcTotalSupply(_avgStableRate);
+  function totalSupply() public pure virtual override returns (uint256) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
-  function getTotalSupplyLastUpdated() external view override returns (uint40) {
-    return _totalSupplyTimestamp;
+  function getTotalSupplyLastUpdated() external pure override returns (uint40) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
-  function principalBalanceOf(address user) external view virtual override returns (uint256) {
-    return super.balanceOf(user);
+  function principalBalanceOf(address) external pure virtual override returns (uint256) {
+    return 0;
   }

   /// @inheritdoc IStableDebtToken
@@ -3061,58 +2973,6 @@ contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
     return _underlyingAsset;
   }

-  /**
-   * @notice Calculates the total supply
-   * @param avgRate The average rate at which the total supply increases
-   * @return The debt balance of the user since the last burn/mint action
-   */
-  function _calcTotalSupply(uint256 avgRate) internal view returns (uint256) {
-    uint256 principalSupply = super.totalSupply();
-
-    if (principalSupply == 0) {
-      return 0;
-    }
-
-    uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
-      avgRate,
-      _totalSupplyTimestamp
-    );
-
-    return principalSupply.rayMul(cumulatedInterest);
-  }
-
-  /**
-   * @notice Mints stable debt tokens to a user
-   * @param account The account receiving the debt tokens
-   * @param amount The amount being minted
-   * @param oldTotalSupply The total supply before the minting event
-   */
-  function _mint(address account, uint256 amount, uint256 oldTotalSupply) internal {
-    uint128 castAmount = amount.toUint128();
-    uint128 oldAccountBalance = _userState[account].balance;
-    _userState[account].balance = oldAccountBalance + castAmount;
-
-    if (address(_incentivesController) != address(0)) {
-      _incentivesController.handleAction(account, oldTotalSupply, oldAccountBalance);
-    }
-  }
-
-  /**
-   * @notice Burns stable debt tokens of a user
-   * @param account The user getting his debt burned
-   * @param amount The amount being burned
-   * @param oldTotalSupply The total supply before the burning event
-   */
-  function _burn(address account, uint256 amount, uint256 oldTotalSupply) internal {
-    uint128 castAmount = amount.toUint128();
-    uint128 oldAccountBalance = _userState[account].balance;
-    _userState[account].balance = oldAccountBalance - castAmount;
-
-    if (address(_incentivesController) != address(0)) {
-      _incentivesController.handleAction(account, oldTotalSupply, oldAccountBalance);
-    }
-  }
-
   /// @inheritdoc EIP712Base
   function _EIP712BaseId() internal view override returns (string memory) {
     return name();
@@ -3146,3 +3006,47 @@ contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
     revert(Errors.OPERATION_NOT_SUPPORTED);
   }
 }
+
+// downloads/ZKSYNC/DEFAULT_STABLE_DEBT_TOKEN_IMPL/StableDebtTokenInstance/src/core/instances/StableDebtTokenInstance.sol
+
+contract StableDebtTokenInstance is StableDebtToken {
+  uint256 public constant DEBT_TOKEN_REVISION = 1;
+
+  constructor(IPool pool) StableDebtToken(pool) {}
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

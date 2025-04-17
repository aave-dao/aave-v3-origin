```diff
diff --git a/./downloads/LINEA/UI_POOL_DATA_PROVIDER.sol b/./downloads/MANTLE/UI_POOL_DATA_PROVIDER.sol
index 2a04406..51647f8 100644
--- a/./downloads/LINEA/UI_POOL_DATA_PROVIDER.sol
+++ b/./downloads/MANTLE/UI_POOL_DATA_PROVIDER.sol
@@ -1,7 +1,55 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;

-// downloads/LINEA/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/MANTLE/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/dependencies/chainlink/AggregatorInterface.sol
+
+// Chainlink Contracts v0.8
+
+interface AggregatorInterface {
+  function decimals() external view returns (uint8);
+
+  function description() external view returns (string memory);
+
+  function getRoundData(
+    uint80 _roundId
+  )
+    external
+    view
+    returns (
+      uint80 roundId,
+      int256 answer,
+      uint256 startedAt,
+      uint256 updatedAt,
+      uint80 answeredInRound
+    );
+
+  function latestRoundData()
+    external
+    view
+    returns (
+      uint80 roundId,
+      int256 answer,
+      uint256 startedAt,
+      uint256 updatedAt,
+      uint80 answeredInRound
+    );
+
+  function latestAnswer() external view returns (int256);
+
+  function latestTimestamp() external view returns (uint256);
+
+  function latestRound() external view returns (uint256);
+
+  function getAnswer(uint256 roundId) external view returns (int256);
+
+  function getTimestamp(uint256 roundId) external view returns (uint256);
+
+  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
+
+  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
+}

-// downloads/LINEA/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/interfaces/IEACAggregatorProxy.sol
-
-interface IEACAggregatorProxy {
-  function decimals() external view returns (uint8);
-
-  function latestAnswer() external view returns (int256);
-
-  function latestTimestamp() external view returns (uint256);
-
-  function latestRound() external view returns (uint256);
-
-  function getAnswer(uint256 roundId) external view returns (int256);
-
-  function getTimestamp(uint256 roundId) external view returns (uint256);
-
-  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
-  event NewRound(uint256 indexed roundId, address indexed startedBy);
-}

-// downloads/LINEA/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol
+// downloads/MANTLE/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol

 interface IUiPoolDataProviderV3 {
   struct AggregatedReserveData {
@@ -2241,6 +2324,8 @@ interface IUiPoolDataProviderV3 {
     // v3.1
     bool virtualAccActive;
     uint128 virtualUnderlyingBalance;
+    // v3.3
+    uint128 deficit;
   }

   struct UserReserveData {
@@ -2283,7 +2368,7 @@ interface IUiPoolDataProviderV3 {
   function getEModes(IPoolAddressesProvider provider) external view returns (Emode[] memory);
 }

-// downloads/LINEA/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/AaveProtocolDataProvider.sol
+// downloads/MANTLE/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/AaveProtocolDataProvider.sol

 /**
  * @title AaveProtocolDataProvider
@@ -3587,10 +3675,10 @@ contract AaveProtocolDataProvider is IPoolDataProvider {
     address[] memory reserves = pool.getReservesList();
     TokenData[] memory aTokens = new TokenData[](reserves.length);
     for (uint256 i = 0; i < reserves.length; i++) {
-      DataTypes.ReserveDataLegacy memory reserveData = pool.getReserveData(reserves[i]);
+      address aTokenAddress = pool.getReserveAToken(reserves[i]);
       aTokens[i] = TokenData({
-        symbol: IERC20Detailed(reserveData.aTokenAddress).symbol(),
-        tokenAddress: reserveData.aTokenAddress
+        symbol: IERC20Detailed(aTokenAddress).symbol(),
+        tokenAddress: aTokenAddress
       });
     }
     return aTokens;
@@ -3678,12 +3766,12 @@ contract AaveProtocolDataProvider is IPoolDataProvider {
       uint256 unbacked,
       uint256 accruedToTreasuryScaled,
       uint256 totalAToken,
-      uint256 totalStableDebt,
+      uint256,
       uint256 totalVariableDebt,
       uint256 liquidityRate,
       uint256 variableBorrowRate,
-      uint256 stableBorrowRate,
-      uint256 averageStableBorrowRate,
+      uint256,
+      uint256,
       uint256 liquidityIndex,
       uint256 variableBorrowIndex,
       uint40 lastUpdateTimestamp
@@ -3712,18 +3800,15 @@ contract AaveProtocolDataProvider is IPoolDataProvider {

   /// @inheritdoc IPoolDataProvider
   function getATokenTotalSupply(address asset) external view override returns (uint256) {
-    DataTypes.ReserveDataLegacy memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
-      asset
-    );
-    return IERC20Detailed(reserve.aTokenAddress).totalSupply();
+    address aTokenAddress = IPool(ADDRESSES_PROVIDER.getPool()).getReserveAToken(asset);
+    return IERC20Detailed(aTokenAddress).totalSupply();
   }

   /// @inheritdoc IPoolDataProvider
   function getTotalDebt(address asset) external view override returns (uint256) {
-    DataTypes.ReserveDataLegacy memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
-      asset
-    );
-    return IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
+    address variableDebtTokenAddress = IPool(ADDRESSES_PROVIDER.getPool())
+      .getReserveVariableDebtToken(asset);
+    return IERC20Detailed(variableDebtTokenAddress).totalSupply();
   }

   /// @inheritdoc IPoolDataProvider
@@ -3777,12 +3862,10 @@ contract AaveProtocolDataProvider is IPoolDataProvider {
       address variableDebtTokenAddress
     )
   {
-    DataTypes.ReserveDataLegacy memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
-      asset
-    );
+    IPool pool = IPool(ADDRESSES_PROVIDER.getPool());

     // @notice all stable debt related parameters deprecated in v3.2.0
-    return (reserve.aTokenAddress, address(0), reserve.variableDebtTokenAddress);
+    return (pool.getReserveAToken(asset), address(0), pool.getReserveVariableDebtToken(asset));
   }

   /// @inheritdoc IPoolDataProvider
@@ -3816,23 +3899,28 @@ contract AaveProtocolDataProvider is IPoolDataProvider {
   function getVirtualUnderlyingBalance(address asset) external view override returns (uint256) {
     return IPool(ADDRESSES_PROVIDER.getPool()).getVirtualUnderlyingBalance(asset);
   }
+
+  /// @inheritdoc IPoolDataProvider
+  function getReserveDeficit(address asset) external view override returns (uint256) {
+    return IPool(ADDRESSES_PROVIDER.getPool()).getReserveDeficit(asset);
+  }
 }

-// downloads/LINEA/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol
+// downloads/MANTLE/UI_POOL_DATA_PROVIDER/UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol

 contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
   using WadRayMath for uint256;
   using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
   using UserConfiguration for DataTypes.UserConfigurationMap;

-  IEACAggregatorProxy public immutable networkBaseTokenPriceInUsdProxyAggregator;
-  IEACAggregatorProxy public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
+  AggregatorInterface public immutable networkBaseTokenPriceInUsdProxyAggregator;
+  AggregatorInterface public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
   uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
   address public constant MKR_ADDRESS = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

   constructor(
-    IEACAggregatorProxy _networkBaseTokenPriceInUsdProxyAggregator,
-    IEACAggregatorProxy _marketReferenceCurrencyPriceInUsdProxyAggregator
+    AggregatorInterface _networkBaseTokenPriceInUsdProxyAggregator,
+    AggregatorInterface _marketReferenceCurrencyPriceInUsdProxyAggregator
   ) {
     networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
     marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
@@ -3930,6 +4018,7 @@ contract UiPoolDataProviderV3 is IUiPoolDataProviderV3 {
       } catch {}

       // v3 only
+      reserveData.deficit = uint128(pool.getReserveDeficit(reserveData.underlyingAsset));
       reserveData.debtCeiling = reserveConfigurationMap.getDebtCeiling();
       reserveData.debtCeilingDecimals = poolDataProvider.getDebtCeilingDecimals();
       (reserveData.borrowCap, reserveData.supplyCap) = reserveConfigurationMap.getCaps();
```

```diff
diff --git a/./downloads/ARBITRUM/L2_POOL_IMPL.sol b/./downloads/ZKSYNC/L2_POOL_IMPL.sol
index 4227407..656ea6e 100644
--- a/./downloads/ARBITRUM/L2_POOL_IMPL.sol
+++ b/./downloads/ZKSYNC/L2_POOL_IMPL.sol

-// downloads/ARBITRUM/L2_POOL_IMPL/L2PoolInstanceWithCustomInitialize/src/contracts/PoolRevisionFourInitialize.sol
+// downloads/ZKSYNC/L2_POOL_IMPL/L2PoolInstance/src/core/instances/L2PoolInstance.sol

-library PoolRevisionFourInitialize {
-  using ReserveLogic for DataTypes.ReserveCache;
-  using ReserveLogic for DataTypes.ReserveData;
-  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
-
-  function initialize(
-    uint256 reservesCount,
-    mapping(uint256 => address) storage _reservesList,
-    mapping(address => DataTypes.ReserveData) storage _reserves
-  ) external {
-    for (uint256 i = 0; i < reservesCount; i++) {
-      address currentReserveAddress = _reservesList[i];
-      // if this reserve was dropped already - skip
-      // GHO is the special case
-      if (
-        currentReserveAddress == address(0) ||
-        currentReserveAddress == AaveV3EthereumAssets.GHO_UNDERLYING
-      ) {
-        continue;
-      }
-
-      DataTypes.ReserveData storage currentReserve = _reserves[currentReserveAddress];
-      DataTypes.ReserveCache memory reserveCache = currentReserve.cache();
-      currentReserve.updateState(reserveCache);
-
-      uint256 balanceOfUnderlying = IERC20(currentReserveAddress).balanceOf(
-        reserveCache.aTokenAddress
-      );
-      uint256 aTokenTotalSupply = IERC20(reserveCache.aTokenAddress).totalSupply();
-      uint256 vTokenTotalSupply = IERC20(reserveCache.variableDebtTokenAddress).totalSupply();
-      uint256 sTokenTotalSupply = IERC20(reserveCache.stableDebtTokenAddress).totalSupply();
-
-      // calculate current accruedToTreasury
-      uint256 accruedToTreasury = WadRayMath.rayMul(
-        currentReserve.accruedToTreasury,
-        reserveCache.nextLiquidityIndex
-      );
-
-      uint256 currentVirtualBalance = (aTokenTotalSupply + accruedToTreasury) -
-        (sTokenTotalSupply + vTokenTotalSupply);
-      if (balanceOfUnderlying < currentVirtualBalance) {
-        currentVirtualBalance = balanceOfUnderlying;
-      }
-      currentReserve.virtualUnderlyingBalance = SafeCast.toUint128(currentVirtualBalance);
-
-      DataTypes.ReserveConfigurationMap memory currentConfiguration = currentReserve.configuration;
-      currentConfiguration.setVirtualAccActive(true);
-      currentReserve.configuration = currentConfiguration;
-    }
-  }
-}
-
-// downloads/ARBITRUM/L2_POOL_IMPL/L2PoolInstanceWithCustomInitialize/src/contracts/PoolInstanceWithCustomInitialize.sol
-
-/**
- * @notice Pool instance with custom initialize for existing pools
- */
-contract PoolInstanceWithCustomInitialize is PoolInstance {
+contract L2PoolInstance is L2Pool, PoolInstance {
   constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}
-
-  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
-    require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
-    PoolRevisionFourInitialize.initialize(_reservesCount, _reservesList, _reserves);
-  }
-}
-
-// downloads/ARBITRUM/L2_POOL_IMPL/L2PoolInstanceWithCustomInitialize/src/contracts/L2PoolInstanceWithCustomInitialize.sol
-
-/**
- * @notice L2Pool instance with custom initialize for existing pools
- */
-contract L2PoolInstanceWithCustomInitialize is L2Pool, PoolInstanceWithCustomInitialize {
-  constructor(IPoolAddressesProvider provider) PoolInstanceWithCustomInitialize(provider) {}
 }
```

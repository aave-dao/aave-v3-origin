```diff
diff --git a/./downloads/GNOSIS/POOL_IMPL.sol b/./downloads/ZKSYNC/POOL_IMPL.sol

-// downloads/GNOSIS/POOL_IMPL/PoolInstanceWithCustomInitialize/lib/aave-v3-origin/src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/POOL_IMPL/PoolInstance/src/core/contracts/interfaces/IPool.sol

 /**
  * @title IPool
@@ -3634,40 +3015,40 @@ interface IPool {
   /**
    * @notice Gets the address of the external FlashLoanLogic
    */
-  function getFlashLoanLogic() external returns (address);
+  function getFlashLoanLogic() external view returns (address);

   /**
    * @notice Gets the address of the external BorrowLogic
    */
-  function getBorrowLogic() external returns (address);
+  function getBorrowLogic() external view returns (address);

   /**
    * @notice Gets the address of the external BridgeLogic
    */
-  function getBridgeLogic() external returns (address);
+  function getBridgeLogic() external view returns (address);

   /**
    * @notice Gets the address of the external EModeLogic
    */
-  function getEModeLogic() external returns (address);
+  function getEModeLogic() external view returns (address);

   /**
    * @notice Gets the address of the external LiquidationLogic
    */
-  function getLiquidationLogic() external returns (address);
+  function getLiquidationLogic() external view returns (address);

   /**
    * @notice Gets the address of the external PoolLogic
    */
-  function getPoolLogic() external returns (address);
+  function getPoolLogic() external view returns (address);

   /**
    * @notice Gets the address of the external SupplyLogic
    */
-  function getSupplyLogic() external returns (address);
+  function getSupplyLogic() external view returns (address);
 }

-// downloads/GNOSIS/POOL_IMPL/PoolInstanceWithCustomInitialize/lib/aave-v3-origin/src/core/instances/PoolInstance.sol
+// downloads/ZKSYNC/POOL_IMPL/PoolInstance/src/core/instances/PoolInstance.sol

 contract PoolInstance is Pool {
   uint256 public constant POOL_REVISION = 4;
@@ -10182,71 +8820,3 @@ contract PoolInstance is Pool {
     return POOL_REVISION;
   }
 }
-
-// downloads/GNOSIS/POOL_IMPL/PoolInstanceWithCustomInitialize/src/contracts/PoolRevisionFourInitialize.sol
-
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
-// downloads/GNOSIS/POOL_IMPL/PoolInstanceWithCustomInitialize/src/contracts/PoolInstanceWithCustomInitialize.sol
-
-/**
- * @notice Pool instance with custom initialize for existing pools
- */
-contract PoolInstanceWithCustomInitialize is PoolInstance {
-  constructor(IPoolAddressesProvider provider) PoolInstance(provider) {}
-
-  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
-    require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
-    PoolRevisionFourInitialize.initialize(_reservesCount, _reservesList, _reserves);
-  }
-}
```

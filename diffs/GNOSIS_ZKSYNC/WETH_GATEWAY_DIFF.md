```diff
diff --git a/./downloads/GNOSIS/WETH_GATEWAY.sol b/./downloads/ZKSYNC/WETH_GATEWAY.sol

-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/WrappedTokenGatewayV3.sol
+// downloads/ZKSYNC/WETH_GATEWAY/WrappedTokenGatewayV3/src/periphery/contracts/misc/WrappedTokenGatewayV3.sol

 /**
  * @dev This contract is an upgrade of the WrappedTokenGatewayV3 contract, with immutable pool address.
@@ -2808,8 +2987,8 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
   using UserConfiguration for DataTypes.UserConfigurationMap;
   using GPv2SafeERC20 for IERC20;

-  IWETH public immutable WETH;
-  IPool public immutable POOL;
+  IWETH internal immutable WETH;
+  IPool internal immutable POOL;

   /**
    * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
```

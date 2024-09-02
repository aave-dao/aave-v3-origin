```diff
diff --git a/./downloads/MAINNET/SWAP_COLLATERAL_ADAPTER.sol b/./downloads/ETHERFI/SWAP_COLLATERAL_ADAPTER.sol

-// downloads/MAINNET/SWAP_COLLATERAL_ADAPTER/ParaSwapLiquiditySwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/BaseParaSwapAdapter.sol
+// downloads/ETHERFI/SWAP_COLLATERAL_ADAPTER/ParaSwapLiquiditySwapAdapter/src/periphery/contracts/adapters/paraswap/BaseParaSwapAdapter.sol

 /**
  * @title BaseParaSwapAdapter
@@ -2192,7 +2343,9 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
    * @dev Get the aToken associated to the asset
    * @return address of the aToken
    */
-  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
+  function _getReserveData(
+    address asset
+  ) internal view returns (DataTypes.ReserveDataLegacy memory) {
     return POOL.getReserveData(asset);
   }

@@ -2253,7 +2406,7 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
   }
 }
```

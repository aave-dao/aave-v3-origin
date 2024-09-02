```diff
diff --git a/./downloads/MAINNET/WITHDRAW_SWAP_ADAPTER.sol b/./downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER.sol

-// downloads/MAINNET/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/BaseParaSwapAdapter.sol
+// downloads/ETHERFI/WITHDRAW_SWAP_ADAPTER/ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/BaseParaSwapAdapter.sol

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

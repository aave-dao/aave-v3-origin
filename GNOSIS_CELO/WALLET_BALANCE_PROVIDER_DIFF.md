```diff
diff --git a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol b/./downloads/CELO/WALLET_BALANCE_PROVIDER.sol
index cc18346..71277ff 100644
--- a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol
+++ b/./downloads/CELO/WALLET_BALANCE_PROVIDER.sol

-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol
+// downloads/CELO/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol

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

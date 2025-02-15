```diff
diff --git a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol b/./downloads/SONIC/WALLET_BALANCE_PROVIDER.sol
index cc18346..e4cf53b 100644
--- a/./downloads/GNOSIS/WALLET_BALANCE_PROVIDER.sol
+++ b/./downloads/SONIC/WALLET_BALANCE_PROVIDER.sol

-// downloads/GNOSIS/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol
+// downloads/SONIC/WALLET_BALANCE_PROVIDER/WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol

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

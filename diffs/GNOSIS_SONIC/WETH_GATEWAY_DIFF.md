```diff
diff --git a/./downloads/GNOSIS/WETH_GATEWAY.sol b/./downloads/SONIC/WETH_GATEWAY.sol
index 07a0619..9378337 100644
--- a/./downloads/GNOSIS/WETH_GATEWAY.sol
+++ b/./downloads/SONIC/WETH_GATEWAY.sol

-// downloads/GNOSIS/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol
+// downloads/SONIC/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol

 /**
  * @dev This contract is an upgrade of the WrappedTokenGatewayV3 contract, with immutable pool address.
@@ -2900,8 +2954,8 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
   using UserConfiguration for DataTypes.UserConfigurationMap;
   using GPv2SafeERC20 for IERC20;

-  IWETH internal immutable WETH;
-  IPool internal immutable POOL;
+  IWETH public immutable WETH;
+  IPool public immutable POOL;

   /**
    * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
@@ -2932,7 +2986,7 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
    * @param to address of the user who will receive native ETH
    */
   function withdrawETH(address, uint256 amount, address to) external override {
-    IAToken aWETH = IAToken(POOL.getReserveData(address(WETH)).aTokenAddress);
+    IAToken aWETH = IAToken(POOL.getReserveAToken(address(WETH)));
     uint256 userBalance = aWETH.balanceOf(msg.sender);
     uint256 amountToWithdraw = amount;

@@ -2952,8 +3006,9 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
    * @param onBehalfOf the address for which msg.sender is repaying
    */
   function repayETH(address, uint256 amount, address onBehalfOf) external payable override {
-    uint256 paybackAmount = IERC20((POOL.getReserveData(address(WETH))).variableDebtTokenAddress)
-      .balanceOf(onBehalfOf);
+    uint256 paybackAmount = IERC20(POOL.getReserveVariableDebtToken(address(WETH))).balanceOf(
+      onBehalfOf
+    );

     if (amount < paybackAmount) {
       paybackAmount = amount;
@@ -3006,7 +3061,7 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
     bytes32 permitR,
     bytes32 permitS
   ) external override {
-    IAToken aWETH = IAToken(POOL.getReserveData(address(WETH)).aTokenAddress);
+    IAToken aWETH = IAToken(POOL.getReserveAToken(address(WETH)));
     uint256 userBalance = aWETH.balanceOf(msg.sender);
     uint256 amountToWithdraw = amount;

@@ -3015,7 +3070,9 @@ contract WrappedTokenGatewayV3 is IWrappedTokenGatewayV3, Ownable {
       amountToWithdraw = userBalance;
     }
     // permit `amount` rather than `amountToWithdraw` to make it easier for front-ends and integrators
-    aWETH.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
+    try
+      aWETH.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS)
+    {} catch {}
     aWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
     POOL.withdraw(address(WETH), amountToWithdraw, address(this));
     WETH.withdraw(amountToWithdraw);
```

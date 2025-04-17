```diff
diff --git a/./downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER.sol b/./downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER.sol
index 116b0dd..7be58b1 100644
--- a/./downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER.sol
+++ b/./downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER.sol
@@ -1,7 +1,55 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;

-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/chainlink/AggregatorInterface.sol
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
+
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol

-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/interfaces/IEACAggregatorProxy.sol
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
-

-// downloads/LINEA/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol
+// downloads/MANTLE/UI_INCENTIVE_DATA_PROVIDER/UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol

 contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
   using UserConfiguration for DataTypes.UserConfigurationMap;
@@ -3834,10 +3913,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -3888,10 +3967,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           rewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             rewardInformation.rewardTokenAddress
           );
-          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          rewardInformation.priceFeedDecimals = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).decimals();
-          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          rewardInformation.rewardPriceFeed = AggregatorInterface(
             rewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -3968,10 +4047,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = aTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();

@@ -4021,10 +4100,10 @@ contract UiIncentiveDataProviderV3 is IUiIncentiveDataProviderV3 {
           userRewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
             userRewardInformation.rewardTokenAddress
           );
-          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
+          userRewardInformation.priceFeedDecimals = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).decimals();
-          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
+          userRewardInformation.rewardPriceFeed = AggregatorInterface(
             userRewardInformation.rewardOracleAddress
           ).latestAnswer();

```

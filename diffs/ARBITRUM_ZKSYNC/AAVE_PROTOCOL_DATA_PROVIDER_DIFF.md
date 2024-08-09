```diff
diff --git a/./downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER.sol b/./downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER.sol
index d0cfca1..35ccb13 100644
--- a/./downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER.sol
+++ b/./downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -77,7 +77,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -96,7 +96,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -323,7 +323,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -395,7 +395,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -503,7 +503,7 @@ library Errors {
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -629,7 +629,7 @@ library WadRayMath {
   }
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -942,7 +942,7 @@ library DataTypes {
   }
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -952,7 +952,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IPoolDataProvider.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IPoolDataProvider.sol
 
 /**
  * @title IPoolDataProvider
@@ -1207,7 +1207,7 @@ interface IPoolDataProvider {
   function getVirtualUnderlyingBalance(address asset) external view returns (uint256);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2039,7 +2039,7 @@ interface IPool {
   function getSupplyLogic() external returns (address);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2676,7 +2676,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -2908,7 +2908,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -2957,7 +2957,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IStableDebtToken.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IStableDebtToken.sol
 
 /**
  * @title IStableDebtToken
@@ -3094,7 +3094,7 @@ interface IStableDebtToken is IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/interfaces/IVariableDebtToken.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/interfaces/IVariableDebtToken.sol
 
 /**
  * @title IVariableDebtToken
@@ -3137,7 +3137,7 @@ interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/ARBITRUM/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/misc/AaveProtocolDataProvider.sol
+// downloads/ZKSYNC/AAVE_PROTOCOL_DATA_PROVIDER/AaveProtocolDataProvider/src/core/contracts/misc/AaveProtocolDataProvider.sol
 
 /**
  * @title AaveProtocolDataProvider
```

```diff
diff --git a/./downloads/LINEA/WETH_GATEWAY.sol b/./downloads/MANTLE/WETH_GATEWAY.sol
index a354ad2..1b33452 100644
--- a/./downloads/LINEA/WETH_GATEWAY.sol
+++ b/./downloads/MANTLE/WETH_GATEWAY.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -24,7 +24,7 @@ abstract contract Context {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -354,7 +354,7 @@ library DataTypes {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -461,7 +461,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -480,7 +480,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -556,7 +556,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -783,7 +783,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -855,7 +855,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/helpers/interfaces/IWETH.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWETH.sol
 
 interface IWETH {
   function deposit() external payable;
@@ -867,7 +867,7 @@ interface IWETH {
   function transferFrom(address src, address dst, uint256 wad) external returns (bool);
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -980,7 +980,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/dependencies/openzeppelin/contracts/Ownable.sol
 
 /**
  * @dev Contract module which provides a basic access control mechanism, where
@@ -1046,7 +1046,7 @@ contract Ownable is Context {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IPool.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -1914,7 +1914,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2498,7 +2498,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -2730,7 +2730,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2783,7 +2783,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/helpers/interfaces/IWrappedTokenGatewayV3.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/interfaces/IWrappedTokenGatewayV3.sol
 
 interface IWrappedTokenGatewayV3 {
   function WETH() external view returns (IWETH);
@@ -2809,7 +2809,7 @@ interface IWrappedTokenGatewayV3 {
   ) external;
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/interfaces/IAToken.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -2943,7 +2943,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/LINEA/WETH_GATEWAY/WrappedTokenGatewayV3/lib/aave-v3-origin/src/contracts/helpers/WrappedTokenGatewayV3.sol
+// downloads/MANTLE/WETH_GATEWAY/WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol
 
 /**
  * @dev This contract is an upgrade of the WrappedTokenGatewayV3 contract, with immutable pool address.
```

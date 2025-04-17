```diff
diff --git a/./downloads/LINEA/CONFIGURATOR_LOGIC.sol b/./downloads/MANTLE/CONFIGURATOR_LOGIC.sol
index 0739b0e..a215049 100644
--- a/./downloads/LINEA/CONFIGURATOR_LOGIC.sol
+++ b/./downloads/MANTLE/CONFIGURATOR_LOGIC.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
 
 library ConfiguratorInputTypes {
   struct InitReserveInput {
@@ -260,7 +260,7 @@ library ConfiguratorInputTypes {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -590,7 +590,7 @@ library DataTypes {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -697,7 +697,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -716,7 +716,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -792,7 +792,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -1019,7 +1019,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
 
 /**
  * @title Proxy
@@ -1100,7 +1100,7 @@ abstract contract Proxy {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1110,7 +1110,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -1137,7 +1137,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256);
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -1200,7 +1200,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPool.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2068,7 +2068,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2652,7 +2652,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -2735,7 +2735,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -2762,7 +2762,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2815,7 +2815,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -2864,7 +2864,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -2889,7 +2889,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/LINEA/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
+// downloads/MANTLE/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
 
 /**
  * @title ConfiguratorLogic library
```

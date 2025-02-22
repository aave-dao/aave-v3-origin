```diff
diff --git a/./downloads/GNOSIS/CONFIGURATOR_LOGIC.sol b/./downloads/CELO/CONFIGURATOR_LOGIC.sol
index a05116a..98c05e0 100644
--- a/./downloads/GNOSIS/CONFIGURATOR_LOGIC.sol
+++ b/./downloads/CELO/CONFIGURATOR_LOGIC.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
 
 library ConfiguratorInputTypes {
   struct InitReserveInput {
@@ -260,7 +260,7 @@ library ConfiguratorInputTypes {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -590,7 +590,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -697,7 +697,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -716,7 +716,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -792,7 +792,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -1019,7 +1019,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
 
 /**
  * @title Proxy
@@ -1100,7 +1100,7 @@ abstract contract Proxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1110,7 +1110,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -1137,7 +1137,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -1200,7 +1200,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPool.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2068,7 +2068,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2652,7 +2652,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -2735,7 +2735,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -2762,7 +2762,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2815,7 +2815,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -2864,7 +2864,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -2889,7 +2889,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
+// downloads/CELO/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
 
 /**
  * @title ConfiguratorLogic library
```

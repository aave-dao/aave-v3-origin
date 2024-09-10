```diff
diff --git a/./downloads/GNOSIS/CONFIGURATOR_LOGIC.sol b/./downloads/ZKSYNC/CONFIGURATOR_LOGIC.sol
index 7f8188b..70934b0 100644
--- a/./downloads/GNOSIS/CONFIGURATOR_LOGIC.sol
+++ b/./downloads/ZKSYNC/CONFIGURATOR_LOGIC.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -297,7 +297,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
 
 /**
  * @title Proxy
@@ -378,7 +378,7 @@ abstract contract Proxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -397,7 +397,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -624,7 +624,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -732,7 +732,7 @@ library Errors {
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
 
 library ConfiguratorInputTypes {
   struct InitReserveInput {
@@ -774,7 +774,7 @@ library ConfiguratorInputTypes {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -1087,7 +1087,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1097,7 +1097,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -1125,7 +1125,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256, uint256);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -1188,7 +1188,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2020,7 +2020,7 @@ interface IPool {
   function getSupplyLogic() external returns (address);
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -2657,7 +2657,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -2684,7 +2684,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -2767,7 +2767,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IInitializableAToken.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -2820,7 +2820,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -2869,7 +2869,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -2894,7 +2894,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/GNOSIS/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
+// downloads/ZKSYNC/CONFIGURATOR_LOGIC/ConfiguratorLogic/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
 
 /**
  * @title ConfiguratorLogic library
```

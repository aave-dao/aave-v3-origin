```diff
diff --git a/./downloads/GNOSIS/POOL_CONFIGURATOR_IMPL.sol b/./downloads/SONIC/POOL_CONFIGURATOR_IMPL.sol
index 4b3c4ad..42703d8 100644
--- a/./downloads/GNOSIS/POOL_CONFIGURATOR_IMPL.sol
+++ b/./downloads/SONIC/POOL_CONFIGURATOR_IMPL.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
 
 library ConfiguratorInputTypes {
   struct InitReserveInput {
@@ -260,7 +260,7 @@ library ConfiguratorInputTypes {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -590,7 +590,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -697,7 +697,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -716,7 +716,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -792,7 +792,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -1019,7 +1019,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -1080,7 +1080,7 @@ library PercentageMath {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
 
 /**
  * @title Proxy
@@ -1161,7 +1161,7 @@ abstract contract Proxy {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/misc/aave-upgradeability/VersionedInitializable.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/misc/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -1238,7 +1238,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IACLManager.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1411,7 +1411,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1421,7 +1421,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IPoolDataProvider.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IPoolDataProvider.sol
 
 /**
  * @title IPoolDataProvider
@@ -1676,7 +1676,7 @@ interface IPoolDataProvider {
   function getReserveDeficit(address asset) external view returns (uint256);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -1703,7 +1703,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -1766,7 +1766,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IPool.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2634,7 +2634,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -3218,7 +3218,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/misc/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -3301,7 +3301,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
 
 /**
  * @title EModeConfiguration library
@@ -3350,7 +3350,7 @@ library EModeConfiguration {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol
 
 /**
  * @title IDefaultInterestRateStrategyV2
@@ -3508,7 +3508,7 @@ interface IDefaultInterestRateStrategyV2 is IReserveInterestRateStrategy {
   function setInterestRateParams(address reserve, InterestRateData calldata rateData) external;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -3535,7 +3535,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -3588,7 +3588,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -3637,7 +3637,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/interfaces/IPoolConfigurator.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/interfaces/IPoolConfigurator.sol
 
 /**
  * @title IPoolConfigurator
@@ -4185,7 +4185,7 @@ interface IPoolConfigurator {
   function MAX_GRACE_PERIOD() external view returns (uint40);
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -4210,7 +4210,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
 
 /**
  * @title ConfiguratorLogic library
@@ -4414,7 +4414,7 @@ library ConfiguratorLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/protocol/pool/PoolConfigurator.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/protocol/pool/PoolConfigurator.sol
 
 /**
  * @title PoolConfigurator
@@ -5027,7 +5027,7 @@ abstract contract PoolConfigurator is VersionedInitializable, IPoolConfigurator
   }
 }
 
-// downloads/GNOSIS/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/instances/PoolConfiguratorInstance.sol
+// downloads/SONIC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/contracts/instances/PoolConfiguratorInstance.sol
 
 contract PoolConfiguratorInstance is PoolConfigurator {
   uint256 public constant CONFIGURATOR_REVISION = 5;
```

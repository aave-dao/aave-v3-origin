```diff
diff --git a/./downloads/ARBITRUM/POOL_CONFIGURATOR_IMPL.sol b/./downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL.sol
index 13d6d9b..a0f776e 100644
--- a/./downloads/ARBITRUM/POOL_CONFIGURATOR_IMPL.sol
+++ b/./downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0 ^0.8.10;
 
-// src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -297,7 +297,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/upgradeability/Proxy.sol
 
 /**
  * @title Proxy
@@ -378,7 +378,7 @@ abstract contract Proxy {
   }
 }
 
-// src/core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -397,7 +397,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -624,7 +624,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -701,7 +701,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -809,7 +809,7 @@ library Errors {
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// src/core/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -870,7 +870,7 @@ library PercentageMath {
   }
 }
 
-// src/core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol
 
 library ConfiguratorInputTypes {
   struct InitReserveInput {
@@ -912,7 +912,7 @@ library ConfiguratorInputTypes {
   }
 }
 
-// src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -1225,7 +1225,7 @@ library DataTypes {
   }
 }
 
-// src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1235,7 +1235,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// src/core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1408,7 +1408,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// src/core/contracts/interfaces/IPoolDataProvider.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IPoolDataProvider.sol
 
 /**
  * @title IPoolDataProvider
@@ -1663,7 +1663,7 @@ interface IPoolDataProvider {
   function getVirtualUnderlyingBalance(address asset) external view returns (uint256);
 }
 
-// src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -1691,7 +1691,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256, uint256);
 }
 
-// src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol
 
 /**
  * @title BaseUpgradeabilityProxy
@@ -1754,7 +1754,7 @@ contract BaseUpgradeabilityProxy is Proxy {
   }
 }
 
-// src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2553,40 +2553,40 @@ interface IPool {
   /**
    * @notice Gets the address of the external FlashLoanLogic
    */
-  function getFlashLoanLogic() external view returns (address);
+  function getFlashLoanLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external BorrowLogic
    */
-  function getBorrowLogic() external view returns (address);
+  function getBorrowLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external BridgeLogic
    */
-  function getBridgeLogic() external view returns (address);
+  function getBridgeLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external EModeLogic
    */
-  function getEModeLogic() external view returns (address);
+  function getEModeLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external LiquidationLogic
    */
-  function getLiquidationLogic() external view returns (address);
+  function getLiquidationLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external PoolLogic
    */
-  function getPoolLogic() external view returns (address);
+  function getPoolLogic() external returns (address);
 
   /**
    * @notice Gets the address of the external SupplyLogic
    */
-  function getSupplyLogic() external view returns (address);
+  function getSupplyLogic() external returns (address);
 }
 
-// src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -3223,7 +3223,7 @@ library ReserveConfiguration {
   }
 }
 
-// src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol
 
 /**
  * @title InitializableUpgradeabilityProxy
@@ -3250,7 +3250,7 @@ contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// src/core/contracts/interfaces/IDefaultInterestRateStrategyV2.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IDefaultInterestRateStrategyV2.sol
 
 /**
  * @title IDefaultInterestRateStrategyV2
@@ -3418,7 +3418,7 @@ interface IDefaultInterestRateStrategyV2 is IReserveInterestRateStrategy {
   function setInterestRateParams(address reserve, InterestRateData calldata rateData) external;
 }
 
-// src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title BaseImmutableAdminUpgradeabilityProxy
@@ -3501,7 +3501,7 @@ contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
   }
 }
 
-// src/core/contracts/interfaces/IInitializableAToken.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -3554,7 +3554,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// src/core/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -3603,7 +3603,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// src/core/contracts/interfaces/IPoolConfigurator.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/interfaces/IPoolConfigurator.sol
 
 /**
  * @title IPoolConfigurator
@@ -4162,20 +4162,20 @@ interface IPoolConfigurator {
    * @notice Gets pending ltv value
    * @param asset The new siloed borrowing state
    */
-  function getPendingLtv(address asset) external view returns (uint256);
+  function getPendingLtv(address asset) external returns (uint256);
 
   /**
    * @notice Gets the address of the external ConfiguratorLogic
    */
-  function getConfiguratorLogic() external view returns (address);
+  function getConfiguratorLogic() external returns (address);
 
   /**
    * @notice Gets the maximum liquidations grace period allowed, in seconds
    */
-  function MAX_GRACE_PERIOD() external view returns (uint40);
+  function MAX_GRACE_PERIOD() external returns (uint40);
 }
 
-// src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol
 
 /**
  * @title InitializableAdminUpgradeabilityProxy
@@ -4200,7 +4200,7 @@ contract InitializableImmutableAdminUpgradeabilityProxy is
   }
 }
 
-// src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol
 
 /**
  * @title ConfiguratorLogic library
@@ -4470,7 +4470,7 @@ library ConfiguratorLogic {
   }
 }
 
-// src/core/contracts/protocol/pool/PoolConfigurator.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/contracts/protocol/pool/PoolConfigurator.sol
 
 /**
  * @title PoolConfigurator
@@ -5104,7 +5104,7 @@ abstract contract PoolConfigurator is VersionedInitializable, IPoolConfigurator
   }
 }
 
-// downloads/ARBITRUM/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/lib/aave-v3-origin/src/core/instances/PoolConfiguratorInstance.sol
+// downloads/ZKSYNC/POOL_CONFIGURATOR_IMPL/PoolConfiguratorInstance/src/core/instances/PoolConfiguratorInstance.sol
 
 contract PoolConfiguratorInstance is PoolConfigurator {
   uint256 public constant CONFIGURATOR_REVISION = 3;
```

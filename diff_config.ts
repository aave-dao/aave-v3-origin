import {AaveV3ZkSync, AaveV3Gnosis} from '@bgd-labs/aave-address-book';

enum Networks {
  GNOSIS = 'GNOSIS',
  ZKSYNC = 'ZKSYNC',
  FACTORY_LOCAL = 'FACTORY_LOCAL'
}

const CONTRACTS: ContractsType = {
  [Networks.GNOSIS]: {
    POOL_ADDRESSES_PROVIDER: {
      name: 'PoolAddressesProvider',
      path: 'PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol',
      address: AaveV3Gnosis.POOL_ADDRESSES_PROVIDER,
    },
    POOL: {
      name: 'Pool',
      path: 'PoolInstance/src/core/instances/PoolInstance.sol',
      address: AaveV3Gnosis.POOL,
    },
    POOL_CONFIGURATOR: {
      name: 'PoolConfigurator',
      path: 'PoolConfiguratorInstance/src/core/instances/PoolConfiguratorInstance.sol',
      address: AaveV3Gnosis.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: 'AaveOracle',
      path: 'AaveOracle/src/core/contracts/misc/AaveOracle.sol',
      address: AaveV3Gnosis.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: 'AaveProtocolDataProvider',
      path: 'AaveProtocolDataProvider/src/core/contracts/misc/AaveProtocolDataProvider.sol',
      address: AaveV3Gnosis.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: 'ACLManager',
      path: 'ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol',
      address: AaveV3Gnosis.ACL_MANAGER,
    },
    COLLECTOR: {
      name: 'Collector',
      path: 'Collector/src/periphery/contracts/treasury/Collector.sol',
      address: AaveV3Gnosis.COLLECTOR,
    },
    DEFAULT_INCENTIVES_CONTROLLER: {
      name: 'RewardsController',
      path: 'RewardsController/src/periphery/contracts/rewards/RewardsController.sol',
      address: AaveV3Gnosis.DEFAULT_INCENTIVES_CONTROLLER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: 'AToken',
      path: 'ATokenInstance/src/core/instances/ATokenInstance.sol',
      address: AaveV3Gnosis.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: 'VariableDebtToken',
      path: 'VariableDebtTokenInstance/src/core/instances/VariableDebtTokenInstance.sol',
      address: AaveV3Gnosis.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    DEFAULT_STABLE_DEBT_TOKEN_IMPL: {
      name: 'StableDebtToken',
      path: 'StableDebtTokenInstance/src/core/instances/StableDebtTokenInstance.sol',
      address: AaveV3Gnosis.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    EMISSION_MANAGER: {
      name: 'EmissionManager',
      path: 'EmissionManager/src/periphery/contracts/rewards/EmissionManager.sol',
      address: AaveV3Gnosis.EMISSION_MANAGER,
    },
    POOL_ADDRESSES_PROVIDER_REGISTRY: {
      name: 'PoolAddressesProviderRegistry',
      path: 'PoolAddressesProviderRegistry/src/core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol',
      address: AaveV3Gnosis.POOL_ADDRESSES_PROVIDER_REGISTRY,
    },
    WETH_GATEWAY: {
      name: 'WrappedTokenGatewayV3',
      path: 'WrappedTokenGatewayV3/src/periphery/contracts/misc/WrappedTokenGatewayV3.sol',
      address: AaveV3Gnosis.WETH_GATEWAY,
    },
    WALLET_BALANCE_PROVIDER: {
      name: 'WalletBalanceProvider',
      path: 'WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol',
      address: AaveV3Gnosis.WALLET_BALANCE_PROVIDER,
    },
    UI_POOL_DATA_PROVIDER: {
      name: 'UiPoolDataProviderV3',
      path: 'UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol',
      address: AaveV3Gnosis.UI_POOL_DATA_PROVIDER,
    },
    UI_INCENTIVE_DATA_PROVIDER: {
      name: 'UiIncentiveDataProviderV3',
      path: 'UiIncentiveDataProviderV3/src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol',
      address: AaveV3Gnosis.UI_INCENTIVE_DATA_PROVIDER,
    },
    CONFIG_ENGINE: {
      name: "AaveV3ConfigEngine",
      path: "AaveV3ConfigEngine/src/periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol",
      address: AaveV3Gnosis.CONFIG_ENGINE,
    },
    STATIC_A_TOKEN_FACTORY: {
      name: "StaticATokenFactory",
      path: "StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenFactory.sol",
      address: AaveV3Gnosis.STATIC_A_TOKEN_FACTORY,
    },
    BORROW_LOGIC: {
      name: 'BorrowLogic',
      path: 'BorrowLogic/src/core/contracts/protocol/libraries/logic/BorrowLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.BORROW_LOGIC,
    },
    BRIDGE_LOGIC: {
      name: 'BridgeLogic',
      path: 'BridgeLogic/src/core/contracts/protocol/libraries/logic/BridgeLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.BRIDGE_LOGIC,
    },
    CONFIGURATOR_LOGIC: {
      name: 'ConfiguratorLogic',
      path: 'ConfiguratorLogic/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol',
      address: '0x6F4964Db83CeCCDc98164796221d5259b922313C',
    },
    EMODE_LOGIC: {
      name: 'EModeLogic',
      path: 'EModeLogic/src/core/contracts/protocol/libraries/logic/EModeLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.E_MODE_LOGIC,
    },
    FLASHLOAN_LOGIC: {
      name: 'FlashLoanLogic',
      path: 'FlashLoanLogic/src/core/contracts/protocol/libraries/logic/FlashLoanLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.FLASHLOAN_LOGIC,
    },
    LIQUIDATION_LOGIC: {
      name: 'LiquidationLogic',
      path: 'LiquidationLogic/src/core/contracts/protocol/libraries/logic/LiquidationLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.LIQUIDATION_LOGIC,
    },
    POOL_LOGIC: {
      name: 'PoolLogic',
      path: 'PoolLogic/src/core/contracts/protocol/libraries/logic/PoolLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.POOL_LOGIC,
    },
    SUPPLY_LOGIC: {
      name: 'SupplyLogic',
      path: 'SupplyLogic/src/core/contracts/protocol/libraries/logic/SupplyLogic.sol',
      address: AaveV3Gnosis.EXTERNAL_LIBRARIES.SUPPLY_LOGIC,
    },
  },
  [Networks.ZKSYNC]: {
    POOL_ADDRESSES_PROVIDER: {
      name: 'PoolAddressesProvider',
      path: 'PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol',
      address: AaveV3ZkSync.POOL_ADDRESSES_PROVIDER,
    },
    POOL: {
      name: 'Pool',
      path: 'PoolInstance/src/core/instances/PoolInstance.sol',
      address: AaveV3ZkSync.POOL,
    },
    POOL_CONFIGURATOR: {
      name: 'PoolConfigurator',
      path: 'PoolConfiguratorInstance/src/core/instances/PoolConfiguratorInstance.sol',
      address: AaveV3ZkSync.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: 'AaveOracle',
      path: 'AaveOracle/src/core/contracts/misc/AaveOracle.sol',
      address: AaveV3ZkSync.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: 'AaveProtocolDataProvider',
      path: 'AaveProtocolDataProvider/src/core/contracts/misc/AaveProtocolDataProvider.sol',
      address: AaveV3ZkSync.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: 'ACLManager',
      path: 'ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol',
      address: AaveV3ZkSync.ACL_MANAGER,
    },
    COLLECTOR: {
      name: 'Collector',
      path: 'Collector/src/periphery/contracts/treasury/Collector.sol',
      address: AaveV3ZkSync.COLLECTOR,
    },
    DEFAULT_INCENTIVES_CONTROLLER: {
      name: 'RewardsController',
      path: 'RewardsController/src/periphery/contracts/rewards/RewardsController.sol',
      address: AaveV3ZkSync.DEFAULT_INCENTIVES_CONTROLLER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: 'AToken',
      path: 'ATokenInstance/src/core/instances/ATokenInstance.sol',
      address: AaveV3ZkSync.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: 'VariableDebtToken',
      path: 'VariableDebtTokenInstance/src/core/instances/VariableDebtTokenInstance.sol',
      address: AaveV3ZkSync.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    DEFAULT_STABLE_DEBT_TOKEN_IMPL: {
      name: 'StableDebtToken',
      path: 'StableDebtTokenInstance/src/core/instances/StableDebtTokenInstance.sol',
      address: AaveV3ZkSync.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    EMISSION_MANAGER: {
      name: 'EmissionManager',
      path: 'EmissionManager/src/periphery/contracts/rewards/EmissionManager.sol',
      address: AaveV3ZkSync.EMISSION_MANAGER,
    },
    POOL_ADDRESSES_PROVIDER_REGISTRY: {
      name: 'PoolAddressesProviderRegistry',
      path: 'PoolAddressesProviderRegistry/src/core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol',
      address: AaveV3ZkSync.POOL_ADDRESSES_PROVIDER_REGISTRY,
    },
    WETH_GATEWAY: {
      name: 'WrappedTokenGatewayV3',
      path: 'WrappedTokenGatewayV3/src/periphery/contracts/misc/WrappedTokenGatewayV3.sol',
      address: AaveV3ZkSync.WETH_GATEWAY,
    },
    WALLET_BALANCE_PROVIDER: {
      name: 'WalletBalanceProvider',
      path: 'WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol',
      address: AaveV3ZkSync.WALLET_BALANCE_PROVIDER,
    },
    UI_POOL_DATA_PROVIDER: {
      name: 'UiPoolDataProviderV3',
      path: 'UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol',
      address: AaveV3ZkSync.UI_POOL_DATA_PROVIDER,
    },
    UI_INCENTIVE_DATA_PROVIDER: {
      name: 'UiIncentiveDataProviderV3',
      path: 'UiIncentiveDataProviderV3/src/periphery/contracts/misc/UiIncentiveDataProviderV3.sol',
      address: AaveV3ZkSync.UI_INCENTIVE_DATA_PROVIDER,
    },
    CONFIG_ENGINE: {
      name: "AaveV3ConfigEngine",
      path: "AaveV3ConfigEngine/src/periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol",
      address: AaveV3ZkSync.CONFIG_ENGINE,
    },
    STATIC_A_TOKEN_FACTORY: {
      name: "StaticATokenFactory",
      path: "StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenFactory.sol",
      address: AaveV3ZkSync.STATIC_A_TOKEN_FACTORY,
    },
    BORROW_LOGIC: {
      name: 'BorrowLogic',
      path: 'BorrowLogic/src/core/contracts/protocol/libraries/logic/BorrowLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.BORROW_LOGIC,
    },
    BRIDGE_LOGIC: {
      name: 'BridgeLogic',
      path: 'BridgeLogic/src/core/contracts/protocol/libraries/logic/BridgeLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.BRIDGE_LOGIC,
    },
    CONFIGURATOR_LOGIC: {
      name: 'ConfiguratorLogic',
      path: 'ConfiguratorLogic/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol',
      address: '0x556ec5b6870d037d242b5d8c0399b3b3c1401f7c',
    },
    EMODE_LOGIC: {
      name: 'EModeLogic',
      path: 'EModeLogic/src/core/contracts/protocol/libraries/logic/EModeLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.E_MODE_LOGIC,
    },
    FLASHLOAN_LOGIC: {
      name: 'FlashLoanLogic',
      path: 'FlashLoanLogic/src/core/contracts/protocol/libraries/logic/FlashLoanLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.FLASHLOAN_LOGIC,
    },
    LIQUIDATION_LOGIC: {
      name: 'LiquidationLogic',
      path: 'LiquidationLogic/src/core/contracts/protocol/libraries/logic/LiquidationLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.LIQUIDATION_LOGIC,
    },
    POOL_LOGIC: {
      name: 'PoolLogic',
      path: 'PoolLogic/src/core/contracts/protocol/libraries/logic/PoolLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.POOL_LOGIC,
    },
    SUPPLY_LOGIC: {
      name: 'SupplyLogic',
      path: 'SupplyLogic/src/core/contracts/protocol/libraries/logic/SupplyLogic.sol',
      address: AaveV3ZkSync.EXTERNAL_LIBRARIES.SUPPLY_LOGIC,
    },
  },
  [Networks.FACTORY_LOCAL]: {}
};

interface ContractInfo {
  name: string;
  path: string;
  address?: string;
}

type ContractsType = {
  [key in Networks]: {
    [contractName: string]: ContractInfo;
  };
};

const PROXIES = [
  'DEFAULT_INCENTIVES_CONTROLLER',
  'POOL',
  'POOL_CONFIGURATOR',
  'L2_POOL',
  'COLLECTOR',
  "STATIC_A_TOKEN_FACTORY",
];

const CHAIN_ID = {
  [Networks.GNOSIS]: 100,
  [Networks.ZKSYNC]: 324,
  [Networks.FACTORY_LOCAL]: undefined
};

export {CONTRACTS, PROXIES, CHAIN_ID, Networks};

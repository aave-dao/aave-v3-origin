import {AaveV3ZkSync, AaveV3Arbitrum} from '@bgd-labs/aave-address-book';

enum Networks {
  ARBITRUM = 'ARBITRUM',
  ZKSYNC = 'ZKSYNC',
  FACTORY_LOCAL = 'FACTORY_LOCAL'
}

const CONTRACTS: ContractsType = {
  [Networks.ARBITRUM]: {
    POOL_ADDRESSES_PROVIDER: {
      name: 'PoolAddressesProvider',
      path: 'PoolAddressesProvider/@aave/core-v3/contracts/protocol/configuration/PoolAddressesProvider.sol',
      address: AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
    },
    L2_POOL: {
      name: 'L2Pool',
      path: 'L2PoolInstanceWithCustomInitialize/src/contracts/L2PoolInstanceWithCustomInitialize.sol',
      address: AaveV3Arbitrum.POOL,
    },
    POOL_CONFIGURATOR: {
      name: 'PoolConfigurator',
      path: 'PoolConfiguratorInstance/lib/aave-v3-origin/src/core/instances/PoolConfiguratorInstance.sol',
      address: AaveV3Arbitrum.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: 'AaveOracle',
      path: 'AaveOracle/@aave/core-v3/contracts/misc/AaveOracle.sol',
      address: AaveV3Arbitrum.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: 'AaveProtocolDataProvider',
      path: 'AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/misc/AaveProtocolDataProvider.sol',
      address: AaveV3Arbitrum.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: 'ACLManager',
      path: 'ACLManager/@aave/core-v3/contracts/protocol/configuration/ACLManager.sol',
      address: AaveV3Arbitrum.ACL_MANAGER,
    },
    COLLECTOR: {
      name: 'Collector',
      path: 'Collector/src/contracts/Collector.sol',
      address: AaveV3Arbitrum.COLLECTOR,
    },
    DEFAULT_INCENTIVES_CONTROLLER: {
      name: 'RewardsController',
      path: 'RewardsController/lib/aave-v3-periphery/contracts/rewards/RewardsController.sol',
      address: AaveV3Arbitrum.DEFAULT_INCENTIVES_CONTROLLER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: 'AToken',
      path: 'AToken/lib/aave-v3-core/contracts/protocol/tokenization/AToken.sol',
      address: AaveV3Arbitrum.DEFAULT_A_TOKEN_IMPL_REV_2,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: 'VariableDebtToken',
      path: 'VariableDebtToken/lib/aave-v3-core/contracts/protocol/tokenization/VariableDebtToken.sol',
      address: AaveV3Arbitrum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
    },
    DEFAULT_STABLE_DEBT_TOKEN_IMPL: {
      name: 'StableDebtToken',
      path: 'StableDebtToken/src/v3ArbStableDebtToken/StableDebtToken/lib/aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol',
      address: AaveV3Arbitrum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
    },
    EMISSION_MANAGER: {
      name: 'EmissionManager',
      path: 'EmissionManager/@aave/periphery-v3/contracts/rewards/EmissionManager.sol',
      address: AaveV3Arbitrum.EMISSION_MANAGER,
    },
    POOL_ADDRESSES_PROVIDER_REGISTRY: {
      name: 'PoolAddressesProviderRegistry',
      path: 'PoolAddressesProviderRegistry/@aave/core-v3/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol',
      address: AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER_REGISTRY,
    },
    WETH_GATEWAY: {
      name: 'WrappedTokenGatewayV3',
      path: 'WrappedTokenGatewayV3/src/contracts/WrappedTokenGatewayV3.sol',
      address: AaveV3Arbitrum.WETH_GATEWAY,
    },
    WALLET_BALANCE_PROVIDER: {
      name: 'WalletBalanceProvider',
      path: 'WalletBalanceProvider/@aave/periphery-v3/contracts/misc/WalletBalanceProvider.sol',
      address: AaveV3Arbitrum.WALLET_BALANCE_PROVIDER,
    },
    UI_POOL_DATA_PROVIDER: {
      name: 'UiPoolDataProviderV3',
      path: 'UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol',
      address: AaveV3Arbitrum.UI_POOL_DATA_PROVIDER,
    },
    UI_INCENTIVE_DATA_PROVIDER: {
      name: 'UiIncentiveDataProviderV3',
      path: 'UiIncentiveDataProviderV3/@aave/periphery-v3/contracts/misc/UiIncentiveDataProviderV3.sol',
      address: AaveV3Arbitrum.UI_INCENTIVE_DATA_PROVIDER,
    },
    L2_ENCODER: {
      name: 'L2Encoder',
      path: 'L2Encoder/contracts/hardhat-dependency-compiler/@aave/core-v3/contracts/misc/L2Encoder.sol',
      address: AaveV3Arbitrum.L2_ENCODER,
    },
    BORROW_LOGIC: {
      name: 'BorrowLogic',
      path: 'BorrowLogic/src/core/contracts/protocol/libraries/logic/BorrowLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.BORROW_LOGIC,
    },
    BRIDGE_LOGIC: {
      name: 'BridgeLogic',
      path: 'BridgeLogic/src/core/contracts/protocol/libraries/logic/BridgeLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.BRIDGE_LOGIC,
    },
    CONFIGURATOR_LOGIC: {
      name: 'ConfiguratorLogic',
      path: 'ConfiguratorLogic/src/core/contracts/protocol/libraries/logic/ConfiguratorLogic.sol',
      address: '0x6F4964Db83CeCCDc98164796221d5259b922313C',
    },
    EMODE_LOGIC: {
      name: 'EModeLogic',
      path: 'EModeLogic/src/core/contracts/protocol/libraries/logic/EModeLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.E_MODE_LOGIC,
    },
    FLASHLOAN_LOGIC: {
      name: 'FlashLoanLogic',
      path: 'FlashLoanLogic/src/core/contracts/protocol/libraries/logic/FlashLoanLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.FLASHLOAN_LOGIC,
    },
    LIQUIDATION_LOGIC: {
      name: 'LiquidationLogic',
      path: 'LiquidationLogic/src/core/contracts/protocol/libraries/logic/LiquidationLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.LIQUIDATION_LOGIC,
    },
    POOL_LOGIC: {
      name: 'PoolLogic',
      path: 'PoolLogic/src/core/contracts/protocol/libraries/logic/PoolLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.POOL_LOGIC,
    },
    SUPPLY_LOGIC: {
      name: 'SupplyLogic',
      path: 'SupplyLogic/src/core/contracts/protocol/libraries/logic/SupplyLogic.sol',
      address: AaveV3Arbitrum.EXTERNAL_LIBRARIES.SUPPLY_LOGIC,
    },
  },
  [Networks.ZKSYNC]: {
    POOL_ADDRESSES_PROVIDER: {
      name: 'PoolAddressesProvider',
      path: 'PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol',
      address: AaveV3ZkSync.POOL_ADDRESSES_PROVIDER,
    },
    L2_POOL: {
      name: 'L2Pool',
      path: 'L2PoolInstance/src/core/instances/L2PoolInstance.sol',
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
    L2_ENCODER: {
      name: 'L2Encoder',
      path: 'L2Encoder/src/core/contracts/misc/L2Encoder.sol',
      address: AaveV3ZkSync.L2_ENCODER,
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
      address: '0x3bCCd7E769BC66CdDbFA0fe3BEe6eA41cC2a040e',
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
];

const CHAIN_ID = {
  [Networks.ARBITRUM]: 42161,
  [Networks.ZKSYNC]: 324,
  [Networks.FACTORY_LOCAL]: undefined
};

export {CONTRACTS, PROXIES, CHAIN_ID, Networks};

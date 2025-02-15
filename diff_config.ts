import {AaveV3Sonic, AaveV3Gnosis} from '@bgd-labs/aave-address-book';

enum Networks {
  GNOSIS = 'GNOSIS',
  SONIC = 'SONIC',
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
      path: 'PoolInstance/lib/aave-v3-origin/src/contracts/instances/PoolInstance.sol',
      address: AaveV3Gnosis.POOL,
    },
    POOL_CONFIGURATOR: {
      name: 'PoolConfigurator',
      path: 'PoolConfiguratorInstance/lib/aave-v3-origin/src/contracts/instances/PoolConfiguratorInstance.sol',
      address: AaveV3Gnosis.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: 'AaveOracle',
      path: 'AaveOracle/src/core/contracts/misc/AaveOracle.sol',
      address: AaveV3Gnosis.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: 'AaveProtocolDataProvider',
      path: 'AaveProtocolDataProvider/lib/aave-v3-origin/src/contracts/helpers/AaveProtocolDataProvider.sol',
      address: '0xA2d323DBc43F445aD2d8974F17Be5dab32aAD474',
    },
    ACL_MANAGER: {
      name: 'ACLManager',
      path: 'ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol',
      address: AaveV3Gnosis.ACL_MANAGER,
    },
    COLLECTOR: {
      name: 'Collector',
      path: 'CollectorWithCustomImpl/src/CollectorWithCustomImpl.sol',
      address: AaveV3Gnosis.COLLECTOR,
    },
    DEFAULT_INCENTIVES_CONTROLLER: {
      name: 'RewardsController',
      path: 'RewardsController/src/periphery/contracts/rewards/RewardsController.sol',
      address: AaveV3Gnosis.DEFAULT_INCENTIVES_CONTROLLER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: 'AToken',
      path: 'AToken/src/core/contracts/protocol/tokenization/AToken.sol',
      address: AaveV3Gnosis.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: 'VariableDebtToken',
      path: 'VariableDebtToken/src/core/contracts/protocol/tokenization/VariableDebtToken.sol',
      address: AaveV3Gnosis.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
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
      path: 'WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol',
      address: AaveV3Gnosis.WETH_GATEWAY,
    },
    WALLET_BALANCE_PROVIDER: {
      name: 'WalletBalanceProvider',
      path: 'WalletBalanceProvider/src/periphery/contracts/misc/WalletBalanceProvider.sol',
      address: AaveV3Gnosis.WALLET_BALANCE_PROVIDER,
    },
    UI_POOL_DATA_PROVIDER: {
      name: 'UiPoolDataProviderV3',
      path: 'UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol',
      address: AaveV3Gnosis.UI_POOL_DATA_PROVIDER,
    },
    UI_INCENTIVE_DATA_PROVIDER: {
      name: 'UiIncentiveDataProviderV3',
      path: 'UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol',
      address: AaveV3Gnosis.UI_INCENTIVE_DATA_PROVIDER,
    },
    BORROW_LOGIC: {
      name: 'BorrowLogic',
      path: 'BorrowLogic/src/contracts/protocol/libraries/logic/BorrowLogic.sol',
      address: '0x62325c94E1c49dcDb5937726aB5D8A4c37bCAd36',
    },
    BRIDGE_LOGIC: {
      name: 'BridgeLogic',
      path: 'BridgeLogic/src/contracts/protocol/libraries/logic/BridgeLogic.sol',
      address: '0x621Ef86D8A5C693a06295BC288B95C12D4CE4994',
    },
    CONFIGURATOR_LOGIC: {
      name: 'ConfiguratorLogic',
      path: 'ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol',
      address: '0x09e88e877B39D883BAFd46b65E7B06CC56963041',
    },
    EMODE_LOGIC: {
      name: 'EModeLogic',
      path: 'EModeLogic/src/contracts/protocol/libraries/logic/EModeLogic.sol',
      address: '0xC31d2362fAeD85dF79d0bec99693D0EB0Abd3f74',
    },
    FLASHLOAN_LOGIC: {
      name: 'FlashLoanLogic',
      path: 'FlashLoanLogic/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol',
      address: '0x34039100cc9584Ae5D741d322e16d0d18CEE8770',
    },
    LIQUIDATION_LOGIC: {
      name: 'LiquidationLogic',
      path: 'LiquidationLogic/src/contracts/protocol/libraries/logic/LiquidationLogic.sol',
      address: '0x4731bF01583F991278692E8727d0700a00A1fBBf',
    },
    POOL_LOGIC: {
      name: 'PoolLogic',
      path: 'PoolLogic/src/contracts/protocol/libraries/logic/PoolLogic.sol',
      address: '0xf8C97539934ee66a67C26010e8e027D77E821B0C',
    },
    SUPPLY_LOGIC: {
      name: 'SupplyLogic',
      path: 'SupplyLogic/src/contracts/protocol/libraries/logic/SupplyLogic.sol',
      address: '0x185477906B46D9b8DE0DEB73A1bBfb87b5b51BC3',
    },
  },
  [Networks.SONIC]: {
    POOL_ADDRESSES_PROVIDER: {
      name: 'PoolAddressesProvider',
      path: 'PoolAddressesProvider/src/contracts/protocol/configuration/PoolAddressesProvider.sol',
      address: AaveV3Sonic.POOL_ADDRESSES_PROVIDER,
    },
    POOL: {
      name: 'Pool',
      path: 'PoolInstance/src/contracts/instances/PoolInstance.sol',
      address: AaveV3Sonic.POOL,
    },
    POOL_CONFIGURATOR: {
      name: 'PoolConfigurator',
      path: 'PoolConfiguratorInstance/src/contracts/instances/PoolConfiguratorInstance.sol',
      address: AaveV3Sonic.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: 'AaveOracle',
      path: 'AaveOracle/src/contracts/misc/AaveOracle.sol',
      address: AaveV3Sonic.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: 'AaveProtocolDataProvider',
      path: 'AaveProtocolDataProvider/src/contracts/helpers/AaveProtocolDataProvider.sol',
      address: AaveV3Sonic.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: 'ACLManager',
      path: 'ACLManager/src/contracts/protocol/configuration/ACLManager.sol',
      address: AaveV3Sonic.ACL_MANAGER,
    },
    COLLECTOR: {
      name: 'Collector',
      path: 'Collector/src/contracts/treasury/Collector.sol',
      address: AaveV3Sonic.COLLECTOR,
    },
    DEFAULT_INCENTIVES_CONTROLLER: {
      name: 'RewardsController',
      path: 'RewardsController/src/contracts/rewards/RewardsController.sol',
      address: AaveV3Sonic.DEFAULT_INCENTIVES_CONTROLLER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: 'AToken',
      path: 'ATokenInstance/src/contracts/instances/ATokenInstance.sol',
      address: AaveV3Sonic.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: 'VariableDebtToken',
      path: 'VariableDebtTokenInstance/src/contracts/instances/VariableDebtTokenInstance.sol',
      address: AaveV3Sonic.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    EMISSION_MANAGER: {
      name: 'EmissionManager',
      path: 'EmissionManager/src/contracts/rewards/EmissionManager.sol',
      address: AaveV3Sonic.EMISSION_MANAGER,
    },
    POOL_ADDRESSES_PROVIDER_REGISTRY: {
      name: 'PoolAddressesProviderRegistry',
      path: 'PoolAddressesProviderRegistry/src/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol',
      address: AaveV3Sonic.POOL_ADDRESSES_PROVIDER_REGISTRY,
    },
    WETH_GATEWAY: {
      name: 'WrappedTokenGatewayV3',
      path: 'WrappedTokenGatewayV3/src/contracts/helpers/WrappedTokenGatewayV3.sol',
      address: AaveV3Sonic.WETH_GATEWAY,
    },
    WALLET_BALANCE_PROVIDER: {
      name: 'WalletBalanceProvider',
      path: 'WalletBalanceProvider/src/contracts/helpers/WalletBalanceProvider.sol',
      address: AaveV3Sonic.WALLET_BALANCE_PROVIDER,
    },
    UI_POOL_DATA_PROVIDER: {
      name: 'UiPoolDataProviderV3',
      path: 'UiPoolDataProviderV3/src/contracts/helpers/UiPoolDataProviderV3.sol',
      address: AaveV3Sonic.UI_POOL_DATA_PROVIDER,
    },
    UI_INCENTIVE_DATA_PROVIDER: {
      name: 'UiIncentiveDataProviderV3',
      path: 'UiIncentiveDataProviderV3/src/contracts/helpers/UiIncentiveDataProviderV3.sol',
      address: AaveV3Sonic.UI_INCENTIVE_DATA_PROVIDER,
    },
    BORROW_LOGIC: {
      name: 'BorrowLogic',
      path: 'BorrowLogic/src/contracts/protocol/libraries/logic/BorrowLogic.sol',
      address: '0x62325c94E1c49dcDb5937726aB5D8A4c37bCAd36',
    },
    BRIDGE_LOGIC: {
      name: 'BridgeLogic',
      path: 'BridgeLogic/src/contracts/protocol/libraries/logic/BridgeLogic.sol',
      address: '0x621Ef86D8A5C693a06295BC288B95C12D4CE4994',
    },
    CONFIGURATOR_LOGIC: {
      name: 'ConfiguratorLogic',
      path: 'ConfiguratorLogic/src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol',
      address: '0x09e88e877B39D883BAFd46b65E7B06CC56963041',
    },
    EMODE_LOGIC: {
      name: 'EModeLogic',
      path: 'EModeLogic/src/contracts/protocol/libraries/logic/EModeLogic.sol',
      address: '0xC31d2362fAeD85dF79d0bec99693D0EB0Abd3f74',
    },
    FLASHLOAN_LOGIC: {
      name: 'FlashLoanLogic',
      path: 'FlashLoanLogic/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol',
      address: '0x34039100cc9584Ae5D741d322e16d0d18CEE8770',
    },
    LIQUIDATION_LOGIC: {
      name: 'LiquidationLogic',
      path: 'LiquidationLogic/src/contracts/protocol/libraries/logic/LiquidationLogic.sol',
      address: '0x4731bF01583F991278692E8727d0700a00A1fBBf',
    },
    POOL_LOGIC: {
      name: 'PoolLogic',
      path: 'PoolLogic/src/contracts/protocol/libraries/logic/PoolLogic.sol',
      address: '0xf8C97539934ee66a67C26010e8e027D77E821B0C',
    },
    SUPPLY_LOGIC: {
      name: 'SupplyLogic',
      path: 'SupplyLogic/src/contracts/protocol/libraries/logic/SupplyLogic.sol',
      address: '0x185477906B46D9b8DE0DEB73A1bBfb87b5b51BC3',
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
  'COLLECTOR',
];

const CHAIN_ID = {
  [Networks.SONIC]: 146,
  [Networks.GNOSIS]: 100,
  [Networks.FACTORY_LOCAL]: undefined
};

export {CONTRACTS, PROXIES, CHAIN_ID, Networks};

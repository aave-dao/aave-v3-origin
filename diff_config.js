import {
  AaveV3Ethereum,
  AaveV3EthereumEtherFi,
} from "@bgd-labs/aave-address-book";

const CONTRACTS = {
  MAINNET: {
    POOL_ADDRESSES_PROVIDER: {
      name: "PoolAddressesProvider",
      path: "PoolAddressesProvider/@aave/core-v3/contracts/protocol/configuration/PoolAddressesProvider.sol",
      address: AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
    },
    POOL: {
      name: "Pool",
      path: "PoolInstanceWithCustomInitialize/src/contracts/PoolInstanceWithCustomInitialize.sol",
      address: AaveV3Ethereum.POOL,
    },
    POOL_CONFIGURATOR: {
      name: "PoolConfigurator",
      path: "PoolConfiguratorInstance/lib/aave-v3-origin/src/core/instances/PoolConfiguratorInstance.sol",
      address: AaveV3Ethereum.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: "AaveOracle",
      path: "AaveOracle/@aave/core-v3/contracts/misc/AaveOracle.sol",
      address: AaveV3Ethereum.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: "AaveProtocolDataProvider",
      path: "AaveProtocolDataProvider/lib/aave-v3-origin/src/core/contracts/misc/AaveProtocolDataProvider.sol",
      address: AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: "ACLManager",
      path: "ACLManager/@aave/core-v3/contracts/protocol/configuration/ACLManager.sol",
      address: AaveV3Ethereum.ACL_MANAGER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: "AToken",
      path: "AToken/@aave/core-v3/contracts/protocol/tokenization/AToken.sol",
      address: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: "VariableDebtToken",
      path: "VariableDebtToken/@aave/core-v3/contracts/protocol/tokenization/VariableDebtToken.sol",
      address: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    DEFAULT_STABLE_DEBT_TOKEN_IMPL: {
      name: "StableDebtToken",
      path: "StableDebtToken/@aave/core-v3/contracts/protocol/tokenization/StableDebtToken.sol",
      address: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    WETH_GATEWAY: {
      name: "WrappedTokenGatewayV3",
      path: "WrappedTokenGatewayV3/src/contracts/WrappedTokenGatewayV3.sol",
      address: AaveV3Ethereum.WETH_GATEWAY,
    },
    UI_POOL_DATA_PROVIDER: {
      name: "UiPoolDataProviderV3",
      path: "UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol",
      address: AaveV3Ethereum.UI_POOL_DATA_PROVIDER,
    },
    CONFIG_ENGINE: {
      name: "AaveV3ConfigEngine",
      path: "AaveV3ConfigEngine/src/periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol",
      address: AaveV3Ethereum.CONFIG_ENGINE,
    },
    REPAY_WITH_COLLATERAL_ADAPTER: {
      name: "ParaSwapRepayAdapter",
      path: "ParaSwapRepayAdapter/@aave/periphery-v3/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol",
      address: AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER,
    },
    WITHDRAW_SWAP_ADAPTER: {
      name: "ParaSwapWithdrawSwapAdapter",
      path: "ParaSwapWithdrawSwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/ParaSwapWithdrawSwapAdapter.sol",
      address: AaveV3Ethereum.WITHDRAW_SWAP_ADAPTER,
    },
    SWAP_COLLATERAL_ADAPTER: {
      name: "ParaSwapLiquiditySwapAdapter",
      path: "ParaSwapLiquiditySwapAdapter/@aave/periphery-v3/contracts/adapters/paraswap/ParaSwapLiquiditySwapAdapter.sol",
      address: AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
    },
    STATIC_A_TOKEN_FACTORY: {
      name: "StaticATokenFactory",
      path: "StaticATokenFactory/src/StaticATokenFactory.sol",
      address: AaveV3Ethereum.STATIC_A_TOKEN_FACTORY,
    },
  },
  ETHERFI: {
    POOL_ADDRESSES_PROVIDER: {
      name: "PoolAddressesProvider",
      path: "PoolAddressesProvider/src/core/contracts/protocol/configuration/PoolAddressesProvider.sol",
      address: AaveV3EthereumEtherFi.POOL_ADDRESSES_PROVIDER,
    },
    POOL: {
      name: "Pool",
      path: "PoolInstance/src/core/instances/PoolInstance.sol",
      address: AaveV3EthereumEtherFi.POOL,
    },
    POOL_CONFIGURATOR: {
      name: "PoolConfigurator",
      path: "PoolConfiguratorInstance/lib/aave-v3-origin/src/core/instances/PoolConfiguratorInstance.sol",
      address: AaveV3EthereumEtherFi.POOL_CONFIGURATOR,
    },
    ORACLE: {
      name: "AaveOracle",
      path: "AaveOracle/src/core/contracts/misc/AaveOracle.sol",
      address: AaveV3EthereumEtherFi.ORACLE,
    },
    AAVE_PROTOCOL_DATA_PROVIDER: {
      name: "AaveProtocolDataProvider",
      path: "AaveProtocolDataProvider/src/core/contracts/misc/AaveProtocolDataProvider.sol",
      address: AaveV3EthereumEtherFi.AAVE_PROTOCOL_DATA_PROVIDER,
    },
    ACL_MANAGER: {
      name: "ACLManager",
      path: "ACLManager/src/core/contracts/protocol/configuration/ACLManager.sol",
      address: AaveV3EthereumEtherFi.ACL_MANAGER,
    },
    DEFAULT_A_TOKEN_IMPL: {
      name: "AToken",
      path: "ATokenInstance/src/core/instances/ATokenInstance.sol",
      address: AaveV3EthereumEtherFi.DEFAULT_A_TOKEN_IMPL_REV_1,
    },
    DEFAULT_VARIABLE_DEBT_TOKEN_IMPL: {
      name: "VariableDebtToken",
      path: "VariableDebtTokenInstance/src/core/instances/VariableDebtTokenInstance.sol",
      address: AaveV3EthereumEtherFi.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    DEFAULT_STABLE_DEBT_TOKEN_IMPL: {
      name: "StableDebtToken",
      path: "StableDebtTokenInstance/src/core/instances/StableDebtTokenInstance.sol",
      address: AaveV3EthereumEtherFi.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
    },
    WETH_GATEWAY: {
      name: "WrappedTokenGatewayV3",
      path: "WrappedTokenGatewayV3/src/periphery/contracts/misc/WrappedTokenGatewayV3.sol",
      address: AaveV3EthereumEtherFi.WETH_GATEWAY,
    },
    UI_POOL_DATA_PROVIDER: {
      name: "UiPoolDataProviderV3",
      path: "UiPoolDataProviderV3/src/periphery/contracts/misc/UiPoolDataProviderV3.sol",
      address: AaveV3EthereumEtherFi.UI_POOL_DATA_PROVIDER,
    },
    CONFIG_ENGINE: {
      name: "AaveV3ConfigEngine",
      path: "AaveV3ConfigEngine/src/periphery/contracts/v3-config-engine/AaveV3ConfigEngine.sol",
      address: AaveV3EthereumEtherFi.CONFIG_ENGINE,
    },
    REPAY_WITH_COLLATERAL_ADAPTER: {
      name: "ParaSwapRepayAdapter",
      path: "ParaSwapRepayAdapter/src/periphery/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol",
      address: AaveV3EthereumEtherFi.REPAY_WITH_COLLATERAL_ADAPTER,
    },
    WITHDRAW_SWAP_ADAPTER: {
      name: "ParaSwapWithdrawSwapAdapter",
      path: "ParaSwapWithdrawSwapAdapter/src/periphery/contracts/adapters/paraswap/ParaSwapWithdrawSwapAdapter.sol",
      address: AaveV3EthereumEtherFi.WITHDRAW_SWAP_ADAPTER,
    },
    SWAP_COLLATERAL_ADAPTER: {
      name: "ParaSwapLiquiditySwapAdapter",
      path: "ParaSwapLiquiditySwapAdapter/src/periphery/contracts/adapters/paraswap/ParaSwapLiquiditySwapAdapter.sol",
      address: AaveV3EthereumEtherFi.SWAP_COLLATERAL_ADAPTER,
    },
    STATIC_A_TOKEN_FACTORY: {
      name: "StaticATokenFactory",
      path: "StaticATokenFactory/src/periphery/contracts/static-a-token/StaticATokenFactory.sol",
      address: AaveV3EthereumEtherFi.STATIC_A_TOKEN_FACTORY,
    },
  },
};

const PROXIES = [
  "DEFAULT_INCENTIVES_CONTROLLER",
  "POOL",
  "POOL_CONFIGURATOR",
  "L2_POOL",
  "COLLECTOR",
  "STATIC_A_TOKEN_FACTORY",
];

const CHAIN_ID = {
  MAINNET: 1,
  ETHERFI: 1,
};

export { CONTRACTS, PROXIES, CHAIN_ID };

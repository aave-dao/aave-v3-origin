// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import 'aave-v3-core/contracts/interfaces/IPoolAddressesProviderRegistry.sol';
import 'aave-v3-core/contracts/interfaces/IPool.sol';
import 'aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import 'aave-v3-core/contracts/interfaces/IAToken.sol';
import 'aave-v3-core/contracts/interfaces/IVariableDebtToken.sol';
import 'aave-v3-core/contracts/interfaces/IStableDebtToken.sol';
import 'aave-v3-core/contracts/interfaces/IACLManager.sol';
import 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import 'aave-v3-core/contracts/misc/AaveProtocolDataProvider.sol';
import 'aave-v3-periphery/contracts/misc/UiPoolDataProviderV3.sol';
import 'aave-v3-periphery/contracts/misc/UiIncentiveDataProviderV3.sol';
import 'aave-v3-periphery/contracts/rewards/interfaces/IEmissionManager.sol';
import 'aave-v3-periphery/contracts/rewards/interfaces/IRewardsController.sol';
import 'aave-v3-periphery/contracts/misc/WalletBalanceProvider.sol';
import 'aave-v3-periphery/contracts/adapters/paraswap/ParaSwapLiquiditySwapAdapter.sol';
import 'aave-v3-periphery/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol';
import 'aave-v3-periphery/contracts/adapters/paraswap/ParaSwapWithdrawSwapAdapter.sol';
import 'aave-v3-periphery/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol';
import 'aave-v3-core/contracts/misc/L2Encoder.sol';
import {ICollector} from 'aave-v3-periphery/contracts/treasury/ICollector.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';

struct ContractsReport {
  IPoolAddressesProviderRegistry poolAddressesProviderRegistry;
  IPoolAddressesProvider poolAddressesProvider;
  IPool poolProxy;
  IPool poolImplementation;
  IPoolConfigurator poolConfiguratorProxy;
  IPoolConfigurator poolConfiguratorImplementation;
  AaveProtocolDataProvider protocolDataProvider;
  IAaveOracle aaveOracle;
  IACLManager aclManager;
  ICollector treasury;
  IDefaultInterestRateStrategyV2 defaultInterestRateStrategy;
  ProxyAdmin proxyAdmin;
  ICollector treasuryImplementation;
  IWrappedTokenGatewayV3 wrappedTokenGateway;
  WalletBalanceProvider walletBalanceProvider;
  UiIncentiveDataProviderV3 uiIncentiveDataProvider;
  UiPoolDataProviderV3 uiPoolDataProvider;
  ParaSwapLiquiditySwapAdapter paraSwapLiquiditySwapAdapter;
  ParaSwapRepayAdapter paraSwapRepayAdapter;
  ParaSwapWithdrawSwapAdapter paraSwapWithdrawSwapAdapter;
  L2Encoder l2Encoder;
  IAToken aToken;
  IVariableDebtToken variableDebtToken;
  IStableDebtToken stableDebtToken;
  IEmissionManager emissionManager;
  IRewardsController rewardsControllerImplementation;
  IRewardsController rewardsControllerProxy;
}

struct MarketReport {
  address poolAddressesProviderRegistry;
  address poolAddressesProvider;
  address poolProxy;
  address poolImplementation;
  address poolConfiguratorProxy;
  address poolConfiguratorImplementation;
  address protocolDataProvider;
  address aaveOracle;
  address defaultInterestRateStrategy;
  address priceOracleSentinel;
  address aclManager;
  address treasury;
  address proxyAdmin;
  address treasuryImplementation;
  address wrappedTokenGateway;
  address walletBalanceProvider;
  address uiIncentiveDataProvider;
  address uiPoolDataProvider;
  address paraSwapLiquiditySwapAdapter;
  address paraSwapRepayAdapter;
  address paraSwapWithdrawSwapAdapter;
  address aaveParaSwapFeeClaimer;
  address l2Encoder;
  address aToken;
  address variableDebtToken;
  address stableDebtToken;
  address emissionManager;
  address rewardsControllerImplementation;
  address rewardsControllerProxy;
  address configEngine;
  address transparentProxyFactory;
  address staticATokenFactoryImplementation;
  address staticATokenFactoryProxy;
  address staticATokenImplementation;
  address revenueSplitter;
}

struct LibrariesReport {
  address borrowLogic;
  address bridgeLogic;
  address configuratorLogic;
  address eModeLogic;
  address flashLoanLogic;
  address liquidationLogic;
  address poolLogic;
  address supplyLogic;
}

struct Roles {
  address marketOwner;
  address poolAdmin;
  address emergencyAdmin;
}

struct MarketConfig {
  address networkBaseTokenPriceInUsdProxyAggregator;
  address marketReferenceCurrencyPriceInUsdProxyAggregator;
  string marketId;
  uint8 oracleDecimals;
  address paraswapAugustusRegistry;
  address paraswapFeeClaimer;
  address l2SequencerUptimeFeed;
  uint256 l2PriceOracleSentinelGracePeriod;
  uint256 providerId;
  bytes32 salt;
  address wrappedNativeToken;
  address proxyAdmin;
  uint128 flashLoanPremiumTotal;
  uint128 flashLoanPremiumToProtocol;
  address treasury; // let empty for deployment of collector, otherwise reuse treasury address
  address treasuryPartner; // let empty for single treasury, or add treasury partner for revenue split between two organizations.
  uint16 treasurySplitPercent; // ignored if treasuryPartner is empty, otherwise the split percent for the first treasury (recipientA, values between 00_01 and 100_00)
}

struct DeployFlags {
  bool l2;
}

struct PoolReport {
  address poolImplementation;
  address poolConfiguratorImplementation;
}

struct MiscReport {
  address priceOracleSentinel;
  address defaultInterestRateStrategy;
}

struct ConfigEngineReport {
  address configEngine;
  address listingEngine;
  address eModeEngine;
  address borrowEngine;
  address collateralEngine;
  address priceFeedEngine;
  address rateEngine;
  address capsEngine;
}

struct StaticATokenReport {
  address transparentProxyFactory;
  address staticATokenImplementation;
  address staticATokenFactoryImplementation;
  address staticATokenFactoryProxy;
}

struct InitialReport {
  address poolAddressesProvider;
  address poolAddressesProviderRegistry;
}

struct SetupReport {
  address poolProxy;
  address poolConfiguratorProxy;
  address rewardsControllerProxy;
  address aclManager;
}

struct PeripheryReport {
  address aaveOracle;
  address proxyAdmin;
  address treasury;
  address treasuryImplementation;
  address emissionManager;
  address rewardsControllerImplementation;
  address revenueSplitter;
}

struct ParaswapReport {
  address paraSwapLiquiditySwapAdapter;
  address paraSwapRepayAdapter;
  address paraSwapWithdrawSwapAdapter;
  address aaveParaSwapFeeClaimer;
}

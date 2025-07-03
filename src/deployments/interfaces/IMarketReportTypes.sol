// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../contracts/interfaces/IPoolAddressesProvider.sol';
import '../../contracts/interfaces/IPoolAddressesProviderRegistry.sol';
import '../../contracts/interfaces/IPool.sol';
import '../../contracts/interfaces/IPoolConfigurator.sol';
import '../../contracts/interfaces/IAaveOracle.sol';
import '../../contracts/interfaces/IAToken.sol';
import '../../contracts/interfaces/IVariableDebtToken.sol';
import '../../contracts/interfaces/IACLManager.sol';
import '../../contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import '../../contracts/helpers/AaveProtocolDataProvider.sol';
import '../../contracts/helpers/UiPoolDataProviderV3.sol';
import '../../contracts/helpers/UiIncentiveDataProviderV3.sol';
import '../../contracts/rewards/interfaces/IEmissionManager.sol';
import '../../contracts/rewards/interfaces/IRewardsController.sol';
import '../../contracts/helpers/WalletBalanceProvider.sol';
import '../../contracts/extensions/paraswap-adapters/ParaSwapLiquiditySwapAdapter.sol';
import '../../contracts/extensions/paraswap-adapters/ParaSwapRepayAdapter.sol';
import '../../contracts/extensions/paraswap-adapters/ParaSwapWithdrawSwapAdapter.sol';
import '../../contracts/helpers/interfaces/IWrappedTokenGatewayV3.sol';
import '../../contracts/helpers/L2Encoder.sol';
import {ICollector} from '../../contracts/treasury/ICollector.sol';

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
  address treasuryImplementation;
  address wrappedTokenGateway;
  address walletBalanceProvider;
  address uiIncentiveDataProvider;
  address uiPoolDataProvider;
  address paraSwapLiquiditySwapAdapter;
  address paraSwapRepayAdapter;
  address paraSwapWithdrawSwapAdapter;
  address l2Encoder;
  address aToken;
  address variableDebtToken;
  address emissionManager;
  address rewardsControllerImplementation;
  address rewardsControllerProxy;
  address configEngine;
  address transparentProxyFactory;
  address staticATokenFactoryImplementation;
  address staticATokenFactoryProxy;
  address staticATokenImplementation;
  address revenueSplitter;
  address dustBin;
  address emptyImplementation;
}

struct LibrariesReport {
  address borrowLogic;
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
  address l2SequencerUptimeFeed;
  uint256 l2PriceOracleSentinelGracePeriod;
  uint256 providerId;
  bytes32 salt;
  address wrappedNativeToken;
  uint128 flashLoanPremium;
  address incentivesProxy;
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
  address interestRateStrategy;
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
  address treasury;
  address treasuryImplementation;
  address emissionManager;
  address rewardsControllerImplementation;
  address revenueSplitter;
  address emptyImplementation;
  address dustBin;
}

struct ParaswapReport {
  address paraSwapLiquiditySwapAdapter;
  address paraSwapRepayAdapter;
  address paraSwapWithdrawSwapAdapter;
}

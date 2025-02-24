// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';

library MarketReportUtils {
  function toContractsReport(
    MarketReport memory report
  ) internal pure returns (ContractsReport memory) {
    return
      ContractsReport({
        poolAddressesProviderRegistry: IPoolAddressesProviderRegistry(
          report.poolAddressesProviderRegistry
        ),
        poolAddressesProvider: IPoolAddressesProvider(report.poolAddressesProvider),
        poolProxy: IPool(report.poolProxy),
        poolImplementation: IPool(report.poolImplementation),
        poolConfiguratorProxy: IPoolConfigurator(report.poolConfiguratorProxy),
        poolConfiguratorImplementation: IPoolConfigurator(report.poolConfiguratorImplementation),
        protocolDataProvider: AaveProtocolDataProvider(report.protocolDataProvider),
        aaveOracle: IAaveOracle(report.aaveOracle),
        aclManager: IACLManager(report.aclManager),
        treasury: ICollector(report.treasury),
        defaultInterestRateStrategy: IDefaultInterestRateStrategyV2(
          report.defaultInterestRateStrategy
        ),
        treasuryImplementation: ICollector(report.treasuryImplementation),
        wrappedTokenGateway: IWrappedTokenGatewayV3(report.wrappedTokenGateway),
        walletBalanceProvider: WalletBalanceProvider(payable(report.walletBalanceProvider)),
        uiIncentiveDataProvider: UiIncentiveDataProviderV3(report.uiIncentiveDataProvider),
        uiPoolDataProvider: UiPoolDataProviderV3(report.uiPoolDataProvider),
        paraSwapLiquiditySwapAdapter: ParaSwapLiquiditySwapAdapter(
          report.paraSwapLiquiditySwapAdapter
        ),
        paraSwapRepayAdapter: ParaSwapRepayAdapter(report.paraSwapRepayAdapter),
        paraSwapWithdrawSwapAdapter: ParaSwapWithdrawSwapAdapter(
          report.paraSwapWithdrawSwapAdapter
        ),
        l2Encoder: L2Encoder(report.l2Encoder),
        aToken: IAToken(report.aToken),
        variableDebtToken: IVariableDebtToken(report.variableDebtToken),
        emissionManager: IEmissionManager(report.emissionManager),
        rewardsControllerImplementation: IRewardsController(report.rewardsControllerImplementation),
        rewardsControllerProxy: IRewardsController(report.rewardsControllerProxy)
      });
  }
}

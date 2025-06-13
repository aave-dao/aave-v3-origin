// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';

library MarketReportUtils {
  function toContractsReport(
    MarketReport memory report
  ) internal pure returns (ContractsReport memory contractsReport) {
    contractsReport.poolAddressesProviderRegistry = IPoolAddressesProviderRegistry(
      report.poolAddressesProviderRegistry
    );
    contractsReport.poolAddressesProvider = IPoolAddressesProvider(report.poolAddressesProvider);
    contractsReport.poolProxy = IPool(report.poolProxy);
    contractsReport.poolImplementation = IPool(report.poolImplementation);
    contractsReport.poolConfiguratorProxy = IPoolConfigurator(report.poolConfiguratorProxy);
    contractsReport.poolConfiguratorImplementation = IPoolConfigurator(
      report.poolConfiguratorImplementation
    );
    contractsReport.protocolDataProvider = AaveProtocolDataProvider(report.protocolDataProvider);
    contractsReport.aaveOracle = IAaveOracle(report.aaveOracle);
    contractsReport.aclManager = IACLManager(report.aclManager);
    contractsReport.treasury = ICollector(report.treasury);
    contractsReport.defaultInterestRateStrategy = IDefaultInterestRateStrategyV2(
      report.defaultInterestRateStrategy
    );
    contractsReport.treasuryImplementation = ICollector(report.treasuryImplementation);
    contractsReport.wrappedTokenGateway = IWrappedTokenGatewayV3(report.wrappedTokenGateway);
    contractsReport.walletBalanceProvider = WalletBalanceProvider(
      payable(report.walletBalanceProvider)
    );
    contractsReport.uiIncentiveDataProvider = UiIncentiveDataProviderV3(
      report.uiIncentiveDataProvider
    );
    contractsReport.uiPoolDataProvider = UiPoolDataProviderV3(report.uiPoolDataProvider);
    contractsReport.paraSwapLiquiditySwapAdapter = ParaSwapLiquiditySwapAdapter(
      report.paraSwapLiquiditySwapAdapter
    );
    contractsReport.paraSwapRepayAdapter = ParaSwapRepayAdapter(report.paraSwapRepayAdapter);
    contractsReport.paraSwapWithdrawSwapAdapter = ParaSwapWithdrawSwapAdapter(
      report.paraSwapWithdrawSwapAdapter
    );
    contractsReport.l2Encoder = L2Encoder(report.l2Encoder);
    contractsReport.aToken = IAToken(report.aToken);
    contractsReport.variableDebtToken = IVariableDebtToken(report.variableDebtToken);
    contractsReport.emissionManager = IEmissionManager(report.emissionManager);
    contractsReport.rewardsControllerImplementation = IRewardsController(
      report.rewardsControllerImplementation
    );
    contractsReport.rewardsControllerProxy = IRewardsController(report.rewardsControllerProxy);
  }
}

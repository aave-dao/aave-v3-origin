// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {TransparentProxyFactory, ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {StataTokenV2} from 'aave-v3-periphery/contracts/static-a-token/StataTokenV2.sol';
import {StataTokenFactory} from 'aave-v3-periphery/contracts/static-a-token/StataTokenFactory.sol';
import {IErrors} from '../../interfaces/IErrors.sol';

contract AaveV3HelpersProcedureTwo is IErrors {
  function _deployStaticAToken(
    address pool,
    address rewardsController,
    address proxyAdmin
  ) internal returns (StaticATokenReport memory staticATokenReport) {
    if (proxyAdmin == address(0)) revert ProxyAdminNotFound();

    staticATokenReport.transparentProxyFactory = address(new TransparentProxyFactory());
    staticATokenReport.staticATokenImplementation = address(
      new StataTokenV2(IPool(pool), IRewardsController(rewardsController))
    );
    staticATokenReport.staticATokenFactoryImplementation = address(
      new StataTokenFactory(
        IPool(pool),
        proxyAdmin,
        ITransparentProxyFactory(staticATokenReport.transparentProxyFactory),
        staticATokenReport.staticATokenImplementation
      )
    );

    staticATokenReport.staticATokenFactoryProxy = ITransparentProxyFactory(
      staticATokenReport.transparentProxyFactory
    ).create(
        staticATokenReport.staticATokenFactoryImplementation,
        proxyAdmin,
        abi.encodeWithSelector(StataTokenFactory.initialize.selector)
      );

    return staticATokenReport;
  }
}

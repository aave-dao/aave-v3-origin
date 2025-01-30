// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../../interfaces/IMarketReportTypes.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {StataTokenV2} from '../../../contracts/extensions/stata-token/StataTokenV2.sol';
import {StataTokenFactory} from '../../../contracts/extensions/stata-token/StataTokenFactory.sol';
import {IErrors} from '../../interfaces/IErrors.sol';

contract AaveV3HelpersProcedureTwo is IErrors {
  function _deployStaticAToken(
    address pool,
    address rewardsController,
    address poolAdmin
  ) internal returns (StaticATokenReport memory staticATokenReport) {
    if (poolAdmin == address(0)) revert PoolAdminNotFound();

    staticATokenReport.transparentProxyFactory = address(new TransparentProxyFactory());
    staticATokenReport.staticATokenImplementation = address(
      new StataTokenV2(IPool(pool), IRewardsController(rewardsController))
    );
    staticATokenReport.staticATokenFactoryImplementation = address(
      new StataTokenFactory(
        IPool(pool),
        poolAdmin,
        ITransparentProxyFactory(staticATokenReport.transparentProxyFactory),
        staticATokenReport.staticATokenImplementation
      )
    );

    staticATokenReport.staticATokenFactoryProxy = ITransparentProxyFactory(
      staticATokenReport.transparentProxyFactory
    ).create(
        staticATokenReport.staticATokenFactoryImplementation,
        poolAdmin,
        abi.encodeWithSelector(StataTokenFactory.initialize.selector)
      );

    return staticATokenReport;
  }
}

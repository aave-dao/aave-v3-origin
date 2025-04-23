// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ATokenInstance} from '../../../contracts/instances/ATokenInstance.sol';
import {VariableDebtTokenInstance} from '../../../contracts/instances/VariableDebtTokenInstance.sol';
import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {IAaveIncentivesController} from '../../../contracts/interfaces/IAaveIncentivesController.sol';

contract AaveV3TokensProcedure {
  struct TokensReport {
    address aToken;
    address variableDebtToken;
  }

  function _deployAaveV3TokensImplementations(
    address poolProxy,
    address rewardsControllerProxy,
    address treasury
  ) internal returns (TokensReport memory) {
    TokensReport memory tokensReport;

    ATokenInstance aToken = new ATokenInstance(IPool(poolProxy), rewardsControllerProxy, treasury);
    VariableDebtTokenInstance variableDebtToken = new VariableDebtTokenInstance(
      IPool(poolProxy),
      rewardsControllerProxy
    );

    tokensReport.aToken = address(aToken);
    tokensReport.variableDebtToken = address(variableDebtToken);

    return tokensReport;
  }
}

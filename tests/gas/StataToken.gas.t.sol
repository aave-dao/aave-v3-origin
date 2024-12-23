// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';
import {StataTokenFactory} from '../../src/contracts/extensions/stata-token/StataTokenFactory.sol';
import {StataTokenV2} from '../../src/contracts/extensions/stata-token/StataTokenV2.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * Scenario suite for statatoken operations.
 */
contract StataToken_gas_Tests is Testhelpers {
  StataTokenV2 public stataToken;

  function setUp() public override {
    super.setUp();
    StataTokenFactory(report.staticATokenFactoryProxy).createStataTokens(
      contracts.poolProxy.getReservesList()
    );
    stataToken = StataTokenV2(
      StataTokenFactory(report.staticATokenFactoryProxy).getStataToken(tokenList.usdx)
    );
  }

  function test_deposit() external {
    uint256 amountToDeposit = 1000e8;
    deal(tokenList.usdx, address(this), amountToDeposit);
    IERC20(tokenList.usdx).approve(address(stataToken), amountToDeposit);

    uint256 shares = stataToken.deposit(amountToDeposit, address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'deposit');

    stataToken.redeem(shares, address(this), address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'redeem');
  }

  function test_depositATokens() external {
    uint256 amountToDeposit = 1000e8;
    _supplyOnReserve(address(this), amountToDeposit, tokenList.usdx);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    IERC20(reserveData.aTokenAddress).approve(address(stataToken), amountToDeposit);

    uint256 shares = stataToken.depositATokens(amountToDeposit, address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'depositATokens');

    stataToken.redeemATokens(shares, address(this), address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'redeemAToken');
  }
}

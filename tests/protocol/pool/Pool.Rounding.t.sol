// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPriceOracleGetter} from '../../../src/contracts/interfaces/IPriceOracleGetter.sol';
import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetERC20, IERC20WithPermit} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';

contract PoolRoundingTests is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;

  address internal user;

  address internal asset;
  address internal aToken;
  address internal vToken;

  function setUp() public {
    initTestEnvironment();

    asset = tokenList.weth;

    aToken = contracts.poolProxy.getReserveAToken(asset);
    vToken = contracts.poolProxy.getReserveVariableDebtToken(asset);

    user = alice;
  }

  function test_debtBalanceInBaseCurrencyShouldRoundUp() external {
    _supplyAndEnableAsCollateral({user: user, amount: 100 ether, asset: asset});

    vm.prank(user);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: 1,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });

    (, uint256 totalDebtBase, , , , uint256 healthFactor) = contracts.poolProxy.getUserAccountData(
      user
    );

    // in previous versions rounding was performed in another way, which resulted in zero debt
    // from v3.5 it should result in 1 debt in base currency
    assertEq(totalDebtBase, 1);
    assertNotEq(healthFactor, type(uint256).max);
  }

  function test_reverts_withdrawShouldRoundDownUserBalance() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 supplyAmount = 8;

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 8 * 1e27 / (2e27 + 1) = 3.9999999999999999999999999980...

    // user balance should be rounded down
    // 3 * (2e27 + 1) / 1e27 = 6.000000000000000000000000003

    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 6);
    assertEq(IAToken(aToken).totalSupply(), 6);

    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 - 1);

    // user balance should be rounded down
    // 3 * (2e27 - 1) / 1e27 = 5.999999999999999999999999997

    assertEq(IAToken(aToken).scaledBalanceOf(user), 3);
    assertEq(IAToken(aToken).balanceOf(user), 5);
    assertEq(IAToken(aToken).totalSupply(), 5);

    vm.expectRevert(abi.encodeWithSelector(Errors.NotEnoughAvailableUserBalance.selector));
    contracts.poolProxy.withdraw({asset: asset, amount: 6, to: user});
  }

  function test_supplyCapShouldRoundDown() external {
    AaveSetters.setLiquidityIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 supplyAmount = 8 * 10 ** IERC20Metadata(asset).decimals();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(
      asset,
      supplyAmount / 10 ** IERC20Metadata(asset).decimals()
    );
    vm.stopPrank();

    vm.startPrank(user);
    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    // user scaled balance should be rounded down
    // 8 * (10 ** decimals) * 1e27 / (2e27 + 1) = 3.9999999999999999999999999980... * (10 ** decimals)
    // rounded equals to 4 * (10 ** decimals) - 1

    // user balance should be rounded down
    // (4 * (10 ** decimals) - 1) * (2e27 + 1) / 1e27 = 7.9999999999999999980... * (10 ** decimals)
    // rounded equals to 8 * (10 ** decimals) - 2

    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });

    assertEq(IAToken(aToken).scaledBalanceOf(user), supplyAmount / 2 - 1);
    assertEq(IAToken(aToken).balanceOf(user), supplyAmount - 2);
    assertEq(IAToken(aToken).totalSupply(), supplyAmount - 2);

    supplyAmount = 5;

    deal(asset, user, supplyAmount);
    IERC20(asset).approve(report.poolProxy, supplyAmount);

    vm.expectRevert(abi.encodeWithSelector(Errors.SupplyCapExceeded.selector));
    contracts.poolProxy.supply({
      asset: asset,
      amount: supplyAmount,
      onBehalfOf: user,
      referralCode: 0
    });
  }

  function test_borrowCapShouldRoundUp() external {
    _supplyAndEnableAsCollateral({user: user, amount: 100 ether, asset: asset});

    AaveSetters.setVariableBorrowIndex(report.poolProxy, asset, 2e27 + 1);

    uint256 borrowAmount = 7 * 10 ** IERC20Metadata(asset).decimals();

    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setBorrowCap(
      asset,
      borrowAmount / 10 ** IERC20Metadata(asset).decimals()
    );
    vm.stopPrank();

    //3.49999999999999999749999999825000000000000000125000000087499999999999... × 10^18

    // user scaled balance should be rounded up
    // (7 * (10 ** decimals) - 5) * 1e27 / (2e27 + 1) = 3.499999999999999997499... × 10^18
    // rounded equals to 3.5 * (10 ** decimals) - 2

    // user balance should be rounded up
    // (3.5 * (10 ** decimals) - 2) * (2e27 + 1) / 1e27 = 6.99999999999999999600000000349... * (10 ** decimals)
    // rounded equals to 7 * (10 ** decimals) - 3

    vm.startPrank(user);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: borrowAmount - 5,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });

    assertEq(IAToken(vToken).scaledBalanceOf(user), borrowAmount / 2 - 2);
    assertEq(IAToken(vToken).balanceOf(user), borrowAmount - 3);
    assertEq(IAToken(vToken).totalSupply(), borrowAmount - 3);

    borrowAmount = 4;

    vm.expectRevert(abi.encodeWithSelector(Errors.BorrowCapExceeded.selector));
    contracts.poolProxy.borrow({
      asset: asset,
      amount: borrowAmount,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: user
    });
  }
}

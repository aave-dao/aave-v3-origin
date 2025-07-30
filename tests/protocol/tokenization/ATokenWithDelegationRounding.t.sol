// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {ATokenWithDelegationInstance} from '../../../src/contracts/instances/ATokenWithDelegationInstance.sol';
import {IATokenWithDelegation} from '../../../src/contracts/interfaces/IATokenWithDelegation.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {ConfiguratorInputTypes} from '../../../src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {IBaseDelegation} from '../../../src/contracts/protocol/tokenization/delegation/interfaces/IBaseDelegation.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';

import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract ATokenWithDelegationInstanceNext is ATokenWithDelegationInstance {
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ATokenWithDelegationInstance(pool, rewardsController, treasury) {}

  function getRevision() internal pure virtual override returns (uint256) {
    return ATOKEN_REVISION + 1;
  }
}

/**
 * ATokenWithDelegation always assumes an exact 1 index.
 */
contract ATokenWithDelegationRoundingTest is TestnetProcedures {
  using WadRayMath for uint256;

  address public underlyingAsset;
  ATokenWithDelegationInstance public aToken;

  uint256 aliceSupplyAmount;
  uint256 aliceScaledBalance;
  uint256 aliceBalance;

  uint256 bobSupplyAmount;
  uint256 bobScaledBalance;
  uint256 bobBalance;

  uint256 totalSupply;

  function setUp() public {
    initTestEnvironment();

    _updateATokens();

    underlyingAsset = tokenList.weth;
    aToken = ATokenWithDelegationInstance(contracts.poolProxy.getReserveAToken(underlyingAsset));

    aliceSupplyAmount = 10 * 1e10;
    bobSupplyAmount = 16 * 1e10;

    AaveSetters.setLiquidityIndex(report.poolProxy, underlyingAsset, 1e27);

    _supplyAndEnableAsCollateral({user: alice, amount: aliceSupplyAmount, asset: underlyingAsset});
    _supplyAndEnableAsCollateral({user: bob, amount: bobSupplyAmount, asset: underlyingAsset});

    aliceScaledBalance = aliceSupplyAmount;
    bobScaledBalance = bobSupplyAmount;

    assertEq(aToken.scaledBalanceOf(alice), aliceScaledBalance);
    assertEq(aToken.scaledBalanceOf(bob), bobScaledBalance);

    assertEq(aToken.scaledTotalSupply(), aliceScaledBalance + bobScaledBalance);

    aliceBalance = aliceSupplyAmount;
    bobBalance = bobSupplyAmount;
    totalSupply = aliceSupplyAmount + bobSupplyAmount;

    assertEq(aToken.balanceOf(alice), aliceBalance);
    assertEq(aToken.balanceOf(bob), bobBalance);

    assertEq(aToken.totalSupply(), aliceSupplyAmount + bobSupplyAmount);
  }

  function _updateATokens() private {
    ATokenWithDelegationInstanceNext aTokenImplementation = new ATokenWithDelegationInstanceNext(
      contracts.poolProxy,
      report.rewardsControllerProxy,
      report.treasury
    );

    address[] memory reserves = contracts.poolProxy.getReservesList();

    for (uint256 i = 0; i < reserves.length; ++i) {
      address reserve = reserves[i];

      vm.startPrank(poolAdmin);
      contracts.poolConfiguratorProxy.updateAToken(
        ConfiguratorInputTypes.UpdateATokenInput({
          asset: reserve,
          name: IERC20Metadata(reserve).name(),
          symbol: IERC20Metadata(reserve).symbol(),
          implementation: address(aTokenImplementation),
          params: ''
        })
      );
      vm.stopPrank();
    }
  }

  function test_getPowerCurrent_and_delegate_shouldRoundDown() external {
    (uint256 aliceVotingPower, uint256 alicePropositionPower) = aToken.getPowersCurrent(alice);

    assertEq(aliceVotingPower, aliceBalance);
    assertEq(alicePropositionPower, aliceBalance);

    (uint256 bobVotingPower, uint256 bobPropositionPower) = aToken.getPowersCurrent(bob);

    assertEq(bobVotingPower, bobBalance);
    assertEq(bobPropositionPower, bobBalance);

    vm.prank(alice);
    aToken.delegate(bob);

    (aliceVotingPower, alicePropositionPower) = aToken.getPowersCurrent(alice);
    (bobVotingPower, bobPropositionPower) = aToken.getPowersCurrent(bob);

    assertEq(aliceVotingPower, 0);
    assertEq(alicePropositionPower, 0);
    assertEq(bobVotingPower, totalSupply);
    assertEq(bobPropositionPower, totalSupply);

    vm.prank(bob);
    aToken.delegate(carol);

    (aliceVotingPower, alicePropositionPower) = aToken.getPowersCurrent(alice);
    (bobVotingPower, bobPropositionPower) = aToken.getPowersCurrent(bob);

    assertEq(aliceVotingPower, 0);
    assertEq(alicePropositionPower, 0);
    assertEq(bobVotingPower, aliceBalance);
    assertEq(bobPropositionPower, aliceBalance);

    vm.prank(alice);
    aToken.delegate(address(0));

    (aliceVotingPower, alicePropositionPower) = aToken.getPowersCurrent(alice);
    (bobVotingPower, bobPropositionPower) = aToken.getPowersCurrent(bob);

    assertEq(aliceVotingPower, aliceBalance);
    assertEq(alicePropositionPower, aliceBalance);
    assertEq(bobVotingPower, 0);
    assertEq(bobPropositionPower, 0);

    vm.prank(bob);
    aToken.delegate(address(0));

    (aliceVotingPower, alicePropositionPower) = aToken.getPowersCurrent(alice);
    (bobVotingPower, bobPropositionPower) = aToken.getPowersCurrent(bob);

    assertEq(aliceVotingPower, aliceBalance);
    assertEq(alicePropositionPower, aliceBalance);
    assertEq(bobVotingPower, bobBalance);
    assertEq(bobPropositionPower, bobBalance);
  }
}

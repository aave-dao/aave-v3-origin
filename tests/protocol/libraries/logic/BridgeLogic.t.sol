// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {MathUtils} from '../../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {WadRayMath} from '../../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TestnetProcedures} from '../../../utils/TestnetProcedures.sol';
import {Errors} from '../../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ReserveLogic} from '../../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {PercentageMath} from '../../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {SafeCast} from '../../../../src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol';
import {IAToken} from '../../../../src/contracts/interfaces/IAToken.sol';
import {DataTypes} from '../../../../src/contracts/protocol/libraries/types/DataTypes.sol';

contract BridgeLogicTests is TestnetProcedures {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveDataLegacy;
  using SafeCast for uint256;

  address internal aUSDX;

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Mint(address indexed token, address indexed to, uint256 amount);
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  function setUp() public {
    initTestEnvironment();

    (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

    vm.prank(roleList.marketOwner);
    contracts.aclManager.addBridge(alice);
    vm.prank(poolAdmin);

    contracts.poolConfiguratorProxy.updateBridgeProtocolFee(2000);

    // Carol supplies USDX
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    vm.warp(block.timestamp + 48000);
  }

  struct MintUnbackedParams {
    address underlyingToken;
    address aTokenAddress;
    address user;
    address onBehalfOf;
    uint256 unbackedAmount;
    bool checkInterestsNonZero;
  }

  function _checkMintUnbackedEffects(
    MintUnbackedParams memory i
  ) internal returns (uint256 expectedIndex, uint256 balanceIncrease, uint256 expectedUnbacked) {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      i.underlyingToken
    );

    uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
      reserveData.currentLiquidityRate,
      reserveData.lastUpdateTimestamp
    );
    expectedIndex = cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    uint256 scaledBalance = IAToken(i.aTokenAddress).scaledBalanceOf(i.onBehalfOf);
    balanceIncrease =
      scaledBalance.rayMul(expectedIndex) -
      scaledBalance.rayMul(IAToken(i.aTokenAddress).getPreviousIndex(i.onBehalfOf));

    if (i.checkInterestsNonZero) {
      assertTrue(
        balanceIncrease > 0,
        'Intention failed: balanceIncrease should be greater than zero'
      );
    }

    vm.expectEmit(i.aTokenAddress);
    emit Transfer(address(0), i.onBehalfOf, i.unbackedAmount + balanceIncrease);
    vm.expectEmit(i.aTokenAddress);
    emit Mint(
      i.user,
      i.onBehalfOf,
      i.unbackedAmount + balanceIncrease,
      balanceIncrease,
      expectedIndex
    );
    vm.expectEmit(address(contracts.poolProxy));
    emit MintUnbacked(i.underlyingToken, i.user, i.onBehalfOf, i.unbackedAmount, 0);

    return (expectedIndex, balanceIncrease, reserveData.unbacked + i.unbackedAmount);
  }

  struct BackUnbackParams {
    address underlyingToken;
    address aTokenAddress;
    address user;
    uint256 backedAmount;
    uint256 fee;
    bool checkInterestsNonZero;
  }

  struct BackUnbackVars {
    uint256 protocolFeeBps;
    uint256 backingAmount;
    uint256 feeToProtocol;
    uint256 feeToLP;
    uint256 added;
    uint256 cumulatedLiquidityInterest;
  }

  function _checkBackUnbackedEffects(
    BackUnbackParams memory p
  )
    internal
    returns (
      uint256 expectedIndex,
      uint256 balanceIncrease,
      uint256 expectedUnbacked,
      uint256 expectedAccruedToTreasury
    )
  {
    BackUnbackVars memory vars;
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      p.underlyingToken
    );

    vars.protocolFeeBps = contracts.poolProxy.BRIDGE_PROTOCOL_FEE();
    vars.backingAmount = (p.backedAmount < reserveData.unbacked)
      ? p.backedAmount
      : reserveData.unbacked;
    vars.feeToProtocol = p.fee.percentMul(vars.protocolFeeBps);
    vars.feeToLP = p.fee - vars.feeToProtocol;
    vars.added = vars.backingAmount + p.fee;

    vars.cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
      reserveData.currentLiquidityRate,
      reserveData.lastUpdateTimestamp
    );
    expectedIndex = vars.cumulatedLiquidityInterest.rayMul(reserveData.liquidityIndex);
    uint256 scaledBalance = IAToken(p.aTokenAddress).scaledBalanceOf(p.user);

    balanceIncrease =
      scaledBalance.rayMul(expectedIndex) -
      scaledBalance.rayMul(IAToken(p.aTokenAddress).getPreviousIndex(p.user));

    if (p.checkInterestsNonZero) {
      assertTrue(
        balanceIncrease > 0,
        'Intention failed: balanceIncrease should be greater than zero'
      );
    }
    uint256 newTotalLiquidity = IAToken(p.aTokenAddress).totalSupply() +
      uint256(reserveData.accruedToTreasury).rayMul(expectedIndex);

    expectedIndex = (vars.feeToLP.wadToRay().rayDiv(newTotalLiquidity.wadToRay()) + WadRayMath.RAY)
      .rayMul(expectedIndex);

    expectedAccruedToTreasury =
      reserveData.accruedToTreasury +
      vars.feeToProtocol.rayDiv(expectedIndex).toUint128();

    vm.expectEmit(p.underlyingToken);
    emit Transfer(p.user, p.aTokenAddress, vars.added);
    vm.expectEmit(address(contracts.poolProxy));
    emit BackUnbacked(p.underlyingToken, p.user, vars.backingAmount, p.fee);
    if (p.backedAmount > reserveData.unbacked) {
      expectedUnbacked = 0;
    } else {
      expectedUnbacked = reserveData.unbacked - p.backedAmount;
    }
    return (expectedIndex, balanceIncrease, expectedUnbacked, expectedAccruedToTreasury);
  }

  function _unbackedMintAction() internal {
    MintUnbackedParams memory checkEffectsInput = MintUnbackedParams({
      underlyingToken: tokenList.usdx,
      aTokenAddress: aUSDX,
      user: alice,
      onBehalfOf: alice,
      unbackedAmount: 1000e6,
      checkInterestsNonZero: false
    });

    (
      uint256 expectedIndex,
      uint256 balanceIncrease,
      uint256 expectedUnbacked
    ) = _checkMintUnbackedEffects(checkEffectsInput);

    uint256 prevBalance = IAToken(aUSDX).balanceOf(alice);

    vm.prank(alice);
    contracts.poolProxy.mintUnbacked(tokenList.usdx, 1000e6, alice, 0);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );

    assertEq(reserveData.liquidityIndex, expectedIndex, 'Index does not match expected index');
    assertEq(
      IAToken(aUSDX).balanceOf(alice),
      prevBalance + 1000e6 + balanceIncrease,
      'AToken balance does not match expected balance'
    );
    assertEq(
      reserveData.unbacked,
      expectedUnbacked,
      'Current unbacked amount not match expected unbacked amount'
    );
  }

  function _backUnbackedAction(
    uint256 backAmount,
    uint256 fee,
    address user,
    address underlyingToken,
    address aToken
  ) internal {
    BackUnbackParams memory input = BackUnbackParams({
      underlyingToken: underlyingToken,
      aTokenAddress: aToken,
      user: user,
      backedAmount: backAmount,
      fee: fee,
      checkInterestsNonZero: false
    });
    (
      uint256 expectedIndex,
      ,
      uint256 expectedUnbacked,
      uint256 expectedAccruedToTreasury
    ) = _checkBackUnbackedEffects(input);

    vm.prank(user);
    contracts.poolProxy.backUnbacked(underlyingToken, backAmount, fee);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      underlyingToken
    );

    assertEq(reserveData.unbacked, expectedUnbacked, 'Unbacked does not match expected result');
    assertEq(reserveData.liquidityIndex, expectedIndex, 'Index does not match expected result');
    assertEq(
      reserveData.accruedToTreasury,
      expectedAccruedToTreasury,
      'Accrued treasury balance does not match expected result'
    );
  }

  function test_revert_unathorized_unbackedMint() public {
    vm.expectRevert(bytes(Errors.CALLER_NOT_BRIDGE));

    vm.prank(bob);
    contracts.poolProxy.mintUnbacked(tokenList.usdx, 1, bob, 0);
  }

  function test_revert_unbackedMint_zero_cap() public {
    vm.expectRevert(bytes(Errors.UNBACKED_MINT_CAP_EXCEEDED));

    vm.prank(alice);
    contracts.poolProxy.mintUnbacked(tokenList.usdx, 1, alice, 0);
  }

  function test_unbackedMint_with_cap() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setUnbackedMintCap(tokenList.usdx, 1000);

    _unbackedMintAction();
  }

  function test_multiple_unbackedMint_with_cap() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setUnbackedMintCap(tokenList.usdx, 4000);

    _unbackedMintAction();
    _unbackedMintAction();
    _unbackedMintAction();
    _unbackedMintAction();
  }

  function test_revert_multiple_unbackedMint_with_cap() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setUnbackedMintCap(tokenList.usdx, 3000);

    _unbackedMintAction();
    _unbackedMintAction();
    _unbackedMintAction();

    vm.expectRevert(bytes(Errors.UNBACKED_MINT_CAP_EXCEEDED));
    vm.prank(alice);
    contracts.poolProxy.mintUnbacked(tokenList.usdx, 1000e6, alice, 0);
  }

  function test_backUnbacked_withoutFee() public {
    test_unbackedMint_with_cap();

    _backUnbackedAction(1000e6, 0, alice, tokenList.usdx, aUSDX);
  }

  function test_backUnbacked_withFee() public {
    test_unbackedMint_with_cap();

    _backUnbackedAction(1000e6, 100e6, alice, tokenList.usdx, aUSDX);
  }

  function test_backUnbacked_onlyFee() public {
    test_unbackedMint_with_cap();

    _backUnbackedAction(0, 120e6, alice, tokenList.usdx, aUSDX);
  }

  function test_multiple_backUnbacked() public {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setUnbackedMintCap(tokenList.usdx, 3000);

    _unbackedMintAction();
    _unbackedMintAction();
    _unbackedMintAction();

    _backUnbackedAction(1000e6, 100e6, alice, tokenList.usdx, aUSDX);
    _backUnbackedAction(5000e6, 0, alice, tokenList.usdx, aUSDX);
    _backUnbackedAction(0, 120e6, alice, tokenList.usdx, aUSDX);
  }

  function test_backUnbacked_but_unbacked_is_zero_without_fee() public {
    _backUnbackedAction(1250e6, 0, alice, tokenList.usdx, aUSDX);
  }

  function test_backUnbacked_but_unbacked_is_zero_with_fee() public {
    _backUnbackedAction(1250e6, 240e6, alice, tokenList.usdx, aUSDX);
  }

  function test_backUnbacked_but_unbacked_is_zero_with_only_fee() public {
    _backUnbackedAction(0, 340e6, alice, tokenList.usdx, aUSDX);
  }
}

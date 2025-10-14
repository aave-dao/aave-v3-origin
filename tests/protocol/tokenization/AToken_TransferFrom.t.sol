// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken, IERC20} from '../../../src/contracts/interfaces/IAToken.sol';
import {IScaledBalanceToken} from '../../../src/contracts/interfaces/IScaledBalanceToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {SupplyLogic} from '../../../src/contracts/protocol/libraries/logic/SupplyLogic.sol';
import {MathUtils} from '../../../src/contracts/protocol/libraries/math/MathUtils.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';
import {MockAToken} from '../../../src/contracts/mocks/tokens/MockAToken.sol';

contract ATokenTransferFromTests is TestnetProcedures {
  using WadRayMath for uint256;

  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

  address public token;
  IAToken public aToken;

  function setUp() public {
    initTestEnvironment(false);
    token = tokenList.wbtc;
    aToken = IAToken(contracts.poolProxy.getReserveAToken(token));
  }

  function test_transferFrom_shouldRevertIfSenderIsNotApproved() external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 100;

    AaveSetters.setATokenBalance(address(aToken), owner, amount, 1e27);

    vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, sender, 0, amount));
    vm.prank(sender);
    aToken.transferFrom(owner, sender, amount);
  }

  function test_transferFrom_shouldRevertIfSenderInsufficientAllowance() external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 100;

    vm.prank(owner);
    aToken.approve(sender, amount - 1);

    AaveSetters.setATokenBalance(address(aToken), owner, amount, 1e27);

    vm.expectRevert(
      abi.encodeWithSelector(ERC20InsufficientAllowance.selector, sender, amount - 1, amount)
    );
    vm.prank(sender);
    aToken.transferFrom(owner, sender, amount);
  }

  function test_transferFrom(uint128 liquidityIndex, uint256 approval) external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 1e18;

    liquidityIndex = uint128(bound(liquidityIndex, 1e27, 100_000e27));
    AaveSetters.setATokenBalance(address(aToken), owner, amount, 1e27);
    AaveSetters.setLiquidityIndex(address(contracts.poolProxy), token, liquidityIndex);
    vm.prank(owner);
    aToken.approve(sender, bound(approval, amount, amount.rayMulCeil(liquidityIndex)));

    uint256 ownerScaledBalanceBefore = aToken.scaledBalanceOf(owner);
    uint256 ownerAllowanceBefore = aToken.allowance(owner, sender);
    uint256 senderBalanceBefore = aToken.balanceOf(sender);

    vm.prank(sender);
    aToken.transferFrom(owner, sender, amount);

    uint256 ownerScaledBalanceAfter = aToken.scaledBalanceOf(owner);
    uint256 ownerAllowanceAfter = aToken.allowance(owner, sender);
    uint256 senderBalanceAfter = aToken.balanceOf(sender);

    assertGe(ownerAllowanceBefore - ownerAllowanceAfter, amount);
    assertGe(senderBalanceAfter - senderBalanceBefore, amount);

    uint256 upscaledDiff = (ownerScaledBalanceBefore - ownerScaledBalanceAfter).rayMulFloor(
      liquidityIndex
    );
    assertGe(upscaledDiff, amount);
  }
}

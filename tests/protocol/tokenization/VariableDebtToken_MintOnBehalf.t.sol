// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {VariableDebtTokenHarness as VariableDebtTokenInstance} from '../../harness/VariableDebtToken.sol';
import {IAaveIncentivesController} from '../../../src/contracts/interfaces/IAaveIncentivesController.sol';
import {IInitializableDebtToken, IScaledBalanceToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {ICreditDelegationToken} from '../../../src/contracts/interfaces/ICreditDelegationToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {ReserveLogic, DataTypes} from '../../../src/contracts/protocol/libraries/logic/ReserveLogic.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {TokenMath} from '../../../src/contracts/protocol/libraries/helpers/TokenMath.sol';
import {ConfiguratorInputTypes, IPool} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';
import {TestnetProcedures, TestVars} from '../../utils/TestnetProcedures.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveSetters} from '../../utils/AaveSetters.sol';

contract VariableDebtToken_MintOnBehalfTests is TestnetProcedures {
  using WadRayMath for uint256;
  using TokenMath for uint256;

  address public token;
  VariableDebtTokenInstance public variableDebtToken;

  function setUp() public {
    initTestEnvironment(false);
    token = tokenList.wbtc;
    variableDebtToken = VariableDebtTokenInstance(
      contracts.poolProxy.getReserveVariableDebtToken(token)
    );
  }

  function test_mint_shouldRevertIfSenderIsNotApproved() external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 100;
    vm.expectRevert(
      abi.encodeWithSelector(
        ICreditDelegationToken.InsufficientBorrowAllowance.selector,
        sender,
        0,
        amount
      )
    );
    vm.prank(address(contracts.poolProxy));
    variableDebtToken.mint(sender, owner, amount, amount, 1e27);
  }

  function test_mint_shouldRevertIfSenderInsufficientAllowance() external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 100;
    vm.prank(owner);
    variableDebtToken.approveDelegation(sender, amount - 1);

    vm.expectRevert(
      abi.encodeWithSelector(
        ICreditDelegationToken.InsufficientBorrowAllowance.selector,
        sender,
        amount - 1,
        amount
      )
    );
    vm.prank(address(contracts.poolProxy));
    variableDebtToken.mint(sender, owner, amount, amount, 1e27);
  }

  function test_mint(uint128 variableBorrowIndex, uint256 approval) external {
    address sender = address(0x1);
    address owner = address(0x2);
    uint256 amount = 1e18;

    variableBorrowIndex = uint128(bound(variableBorrowIndex, 1e27, 100_000e27));
    AaveSetters.setVariableDebtTokenBalance(address(variableDebtToken), owner, amount, 1e27);
    AaveSetters.setVariableBorrowIndex(address(contracts.poolProxy), token, variableBorrowIndex);
    vm.prank(owner);
    variableDebtToken.approveDelegation(
      sender,
      bound(
        approval,
        amount,
        amount.rayDivCeil(variableBorrowIndex).rayMulCeil(variableBorrowIndex)
      )
    );

    uint256 ownerScaledBalanceBefore = variableDebtToken.scaledBalanceOf(owner);
    uint256 ownerAllowanceBefore = variableDebtToken.borrowAllowance(owner, sender);

    vm.prank(address(contracts.poolProxy));
    variableDebtToken.mint(
      sender,
      owner,
      amount,
      amount.rayDivCeil(variableBorrowIndex),
      variableBorrowIndex
    );

    uint256 ownerScaledBalanceAfter = variableDebtToken.scaledBalanceOf(owner);
    uint256 ownerAllowanceAfter = variableDebtToken.borrowAllowance(owner, sender);

    assertGe(ownerAllowanceBefore - ownerAllowanceAfter, amount, 'NOT_ENOUGH_ALLOWANCE_CONSUMED');

    uint256 upscaledDiff = (ownerScaledBalanceAfter - ownerScaledBalanceBefore).rayMulFloor(
      variableBorrowIndex
    );
    assertGe(upscaledDiff, amount, 'NOT_ENOUGH_DEBT_CREATED');
  }
}

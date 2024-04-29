// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';
import {StaticATokenLM, IStaticATokenLM, IERC20} from '../../../src/contracts/extensions/static-a-token/StaticATokenLM.sol';
import {SigUtils} from '../../utils/SigUtils.sol';
import {BaseTest, IAToken, IRewardsController, DataTypes} from './TestBase.sol';

contract StaticATokenMetaTransactions is BaseTest {

  function setUp() public override {
    super.setUp();

    // Testing meta transactions with USDX as WETH does not support permit
    DataTypes.ReserveDataLegacy memory reserveDataUSDX = contracts.poolProxy.getReserveData(address(usdx));
    UNDERLYING = address(usdx);
    A_TOKEN = reserveDataUSDX.aTokenAddress;

    staticATokenLM = StaticATokenLM(factory.getStaticAToken(UNDERLYING));

    vm.startPrank(user);
  }

  function test_validateDomainSeparator() public view {
    address[] memory staticATokens = factory.getStaticATokens();

    for (uint256 i = 0; i < staticATokens.length; i++) {
      bytes32 separator1 = StaticATokenLM(staticATokens[i]).DOMAIN_SEPARATOR();
      for (uint256 j = 0; j < staticATokens.length; j++) {
        if (i != j) {
          bytes32 separator2 = StaticATokenLM(staticATokens[j]).DOMAIN_SEPARATOR();
          assertNotEq(separator1, separator2, 'DOMAIN_SEPARATOR_MUST_BE_UNIQUE');
        }
      }
    }
  }

  function test_metaDepositATokenUnderlyingNoPermit() public {
    uint128 amountToDeposit = 5e6;
    deal(UNDERLYING, user, amountToDeposit);
    IERC20(UNDERLYING).approve(address(staticATokenLM), 1e6);
    IStaticATokenLM.PermitParams memory permitParams;

    // generate combined permit
    SigUtils.DepositPermit memory depositPermit = SigUtils.DepositPermit({
      owner: user,
      spender: spender,
      value: 1e6,
      referralCode: 0,
      fromUnderlying: true,
      nonce: staticATokenLM.nonces(user),
      deadline: block.timestamp + 1 days,
      permit: permitParams
    });
    bytes32 digest = SigUtils.getTypedDepositHash(
      depositPermit,
      staticATokenLM.METADEPOSIT_TYPEHASH(),
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

    IStaticATokenLM.SignatureParams memory sigParams = IStaticATokenLM.SignatureParams(v, r, s);

    uint256 previewDeposit = staticATokenLM.previewDeposit(depositPermit.value);
    staticATokenLM.metaDeposit(
      depositPermit.owner,
      depositPermit.spender,
      depositPermit.value,
      depositPermit.referralCode,
      depositPermit.fromUnderlying,
      depositPermit.deadline,
      permitParams,
      sigParams
    );

    assertEq(staticATokenLM.balanceOf(depositPermit.spender), previewDeposit);
  }

  function test_metaDepositATokenUnderlying() public {
    uint128 amountToDeposit = 5e6;
    deal(UNDERLYING, user, amountToDeposit);

    // permit for aToken deposit
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: address(staticATokenLM),
      value: 1e6,
      nonce: IERC20WithPermit(UNDERLYING).nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      staticATokenLM.PERMIT_TYPEHASH(),
      IERC20WithPermit(UNDERLYING).DOMAIN_SEPARATOR()
    );

    (uint8 pV, bytes32 pR, bytes32 pS) = vm.sign(userPrivateKey, permitDigest);

    IStaticATokenLM.PermitParams memory permitParams = IStaticATokenLM.PermitParams(
      permit.owner,
      permit.spender,
      permit.value,
      permit.deadline,
      pV,
      pR,
      pS
    );

    // generate combined permit
    SigUtils.DepositPermit memory depositPermit = SigUtils.DepositPermit({
      owner: user,
      spender: spender,
      value: permit.value,
      referralCode: 0,
      fromUnderlying: true,
      nonce: staticATokenLM.nonces(user),
      deadline: permit.deadline,
      permit: permitParams
    });
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      userPrivateKey,
      SigUtils.getTypedDepositHash(
        depositPermit,
        staticATokenLM.METADEPOSIT_TYPEHASH(),
        staticATokenLM.DOMAIN_SEPARATOR()
      )
    );

    IStaticATokenLM.SignatureParams memory sigParams = IStaticATokenLM.SignatureParams(v, r, s);

    uint256 previewDeposit = staticATokenLM.previewDeposit(depositPermit.value);
    uint256 shares = staticATokenLM.metaDeposit(
      depositPermit.owner,
      depositPermit.spender,
      depositPermit.value,
      depositPermit.referralCode,
      depositPermit.fromUnderlying,
      depositPermit.deadline,
      permitParams,
      sigParams
    );
    assertEq(shares, previewDeposit);
    assertEq(staticATokenLM.balanceOf(depositPermit.spender), previewDeposit);
  }

  function test_metaDepositAToken() public {
    uint128 amountToDeposit = 5e6;
    _fundUser(amountToDeposit, user);
    _underlyingToAToken(amountToDeposit, user);

    // permit for aToken deposit
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: address(staticATokenLM),
      value: 1e6,
      nonce: IERC20WithPermit(A_TOKEN).nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      staticATokenLM.PERMIT_TYPEHASH(),
      IERC20WithPermit(A_TOKEN).DOMAIN_SEPARATOR()
    );

    (uint8 pV, bytes32 pR, bytes32 pS) = vm.sign(userPrivateKey, permitDigest);

    IStaticATokenLM.PermitParams memory permitParams = IStaticATokenLM.PermitParams(
      permit.owner,
      permit.spender,
      permit.value,
      permit.deadline,
      pV,
      pR,
      pS
    );

    // generate combined permit
    SigUtils.DepositPermit memory depositPermit = SigUtils.DepositPermit({
      owner: user,
      spender: spender,
      value: permit.value,
      referralCode: 0,
      fromUnderlying: false,
      nonce: staticATokenLM.nonces(user),
      deadline: permit.deadline,
      permit: permitParams
    });
    bytes32 digest = SigUtils.getTypedDepositHash(
      depositPermit,
      staticATokenLM.METADEPOSIT_TYPEHASH(),
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

    IStaticATokenLM.SignatureParams memory sigParams = IStaticATokenLM.SignatureParams(v, r, s);

    uint256 previewDeposit = staticATokenLM.previewDeposit(depositPermit.value);

    staticATokenLM.metaDeposit(
      depositPermit.owner,
      depositPermit.spender,
      depositPermit.value,
      depositPermit.referralCode,
      depositPermit.fromUnderlying,
      depositPermit.deadline,
      permitParams,
      sigParams
    );

    assertEq(staticATokenLM.balanceOf(depositPermit.spender), previewDeposit);
  }

  function test_metaWithdraw() public {
    uint128 amountToDeposit = 5e6;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    SigUtils.WithdrawPermit memory permit = SigUtils.WithdrawPermit({
      owner: user,
      spender: spender,
      staticAmount: 0,
      dynamicAmount: 1e6,
      toUnderlying: false,
      nonce: staticATokenLM.nonces(user),
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = SigUtils.getTypedWithdrawHash(
      permit,
      staticATokenLM.METAWITHDRAWAL_TYPEHASH(),
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

    IStaticATokenLM.SignatureParams memory sigParams = IStaticATokenLM.SignatureParams(v, r, s);

    staticATokenLM.metaWithdraw(
      permit.owner,
      permit.spender,
      permit.staticAmount,
      permit.dynamicAmount,
      permit.toUnderlying,
      permit.deadline,
      sigParams
    );

    assertEq(IERC20(A_TOKEN).balanceOf(permit.spender), permit.dynamicAmount);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {ERC4626Upgradeable, ERC4626StataTokenUpgradeable, IERC4626StataToken} from '../../../src/contracts/extensions/stata-token/ERC4626StataTokenUpgradeable.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {SigUtils} from '../../utils/SigUtils.sol';

// Minimal mock as contract is abstract
contract MockERC4626StataTokenUpgradeable is ERC4626StataTokenUpgradeable {
  constructor(IPool pool) ERC4626StataTokenUpgradeable(pool) {}

  function mockInit(address aToken) external initializer {
    __ERC4626StataToken_init(aToken);
  }
}

contract ERC4626StataTokenUpgradeableTest is TestnetProcedures {
  MockERC4626StataTokenUpgradeable internal erc4626Upgradeable;
  address internal underlying;
  address internal aToken;

  address public user;
  uint256 internal userPrivateKey;

  function setUp() public virtual {
    initTestEnvironment(false);

    userPrivateKey = 0xA11CE;
    user = address(vm.addr(userPrivateKey));

    address aUsdx = contracts.poolProxy.getReserveAToken(tokenList.usdx);
    underlying = address(tokenList.usdx);
    aToken = aUsdx;
    erc4626Upgradeable = new MockERC4626StataTokenUpgradeable(contracts.poolProxy);
    erc4626Upgradeable.mockInit(address(aUsdx));
  }

  function test_7201() external pure {
    assertEq(
      keccak256(abi.encode(uint256(keccak256('aave-dao.storage.ERC4626StataToken')) - 1)) &
        ~bytes32(uint256(0xff)),
      0x55029d3f54709e547ed74b2fc842d93107ab1490ab7555dd9dd0bf6451101900
    );
  }

  // ### GETTERS TESTS ###
  function test_convertersAndPreviews(uint128 assets) public view {
    uint256 shares = erc4626Upgradeable.convertToShares(assets);
    assertEq(shares, erc4626Upgradeable.previewDeposit(assets));
    assertEq(shares, erc4626Upgradeable.previewWithdraw(assets));
    assertEq(erc4626Upgradeable.convertToAssets(shares), assets);
    assertEq(erc4626Upgradeable.previewMint(shares), assets);
    assertEq(erc4626Upgradeable.previewRedeem(shares), assets);
  }

  function test_totalAssets_shouldbeZeroOnZeroSupply() external view {
    assertEq(erc4626Upgradeable.totalAssets(), 0);
  }

  // ### DEPOSIT TESTS ###
  function test_depositATokens(
    uint128 unboundedUnderlyingBalance,
    uint256 unboundedAmountToDeposit,
    address receiver
  ) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(unboundedUnderlyingBalance, unboundedAmountToDeposit);
    _fundAToken(env.underlyingBalance, user);

    vm.startPrank(user);
    IERC20(aToken).approve(address(erc4626Upgradeable), env.amountToDeposit);
    uint256 shares = erc4626Upgradeable.depositATokens(env.amountToDeposit, receiver);
    vm.stopPrank();

    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
    assertEq(IERC20(aToken).balanceOf(address(erc4626Upgradeable)), env.actualAmountToDeposit);
    assertEq(IERC20(aToken).balanceOf(user), env.underlyingBalance - env.actualAmountToDeposit);
    assertEq(erc4626Upgradeable.totalAssets(), env.actualAmountToDeposit);
  }

  function test_depositATokens_self() external {
    test_depositATokens(1 ether, 1 ether, user);
  }

  function test_deposit_shouldRevert_insufficientAllowance(uint128 unboundedAssets) external {
    TestEnv memory env = _setupTestEnv(unboundedAssets);
    _fundAToken(env.underlyingBalance, user);

    vm.expectRevert(); // underflows
    vm.prank(user);
    erc4626Upgradeable.depositATokens(env.underlyingBalance, user);
  }

  function test_depositWithPermit_shouldRevert_emptyPermit_noPreApproval(
    uint128 unboundedAssets
  ) external {
    TestEnv memory env = _setupTestEnv(unboundedAssets);
    _fundAToken(env.underlyingBalance, user);
    IERC4626StataToken.SignatureParams memory sig;
    vm.expectRevert(); // will underflow
    vm.prank(user);
    erc4626Upgradeable.depositWithPermit(
      env.underlyingBalance,
      user,
      block.timestamp + 1000,
      sig,
      false
    );
  }

  function test_depositWithPermit_emptyPermit_underlying_preApproval(
    uint128 unboundedAssets,
    uint256 unboundedAmountToDeposit,
    address receiver
  ) external {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(unboundedAssets, unboundedAmountToDeposit);
    _fundUnderlying(env.underlyingBalance, user);
    IERC4626StataToken.SignatureParams memory sig;
    vm.prank(user);
    IERC20(underlying).approve(address(erc4626Upgradeable), env.amountToDeposit);
    vm.prank(user);
    uint256 shares = erc4626Upgradeable.depositWithPermit(
      env.amountToDeposit,
      receiver,
      block.timestamp + 1000,
      sig,
      true
    );

    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
    assertEq(IERC20(aToken).balanceOf(address(erc4626Upgradeable)), env.actualAmountToDeposit);
    assertEq(IERC20(aToken).balanceOf(user), 0);
    assertEq(IERC20(underlying).balanceOf(user), env.underlyingBalance - env.actualAmountToDeposit);
  }

  function test_depositWithPermit_emptyPermit_aToken_preApproval(
    uint128 unboundedAssets,
    uint256 unboundedAmountToDeposit,
    address receiver
  ) external {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(unboundedAssets, unboundedAmountToDeposit);
    _fundAToken(env.underlyingBalance, user);
    IERC4626StataToken.SignatureParams memory sig;
    vm.prank(user);
    IERC20(aToken).approve(address(erc4626Upgradeable), env.amountToDeposit);
    vm.prank(user);
    uint256 shares = erc4626Upgradeable.depositWithPermit(
      env.amountToDeposit,
      receiver,
      block.timestamp + 1000,
      sig,
      false
    );

    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
    assertEq(IERC20(aToken).balanceOf(address(erc4626Upgradeable)), env.actualAmountToDeposit);
    assertEq(IERC20(aToken).balanceOf(user), env.underlyingBalance - env.actualAmountToDeposit);
  }

  function test_depositWithPermit_underlying(
    uint128 unboundedAssets,
    uint256 unboundedAmountToDeposit,
    address receiver
  ) external {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(unboundedAssets, unboundedAmountToDeposit);
    _fundUnderlying(env.underlyingBalance, user);

    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: address(erc4626Upgradeable),
      value: env.amountToDeposit,
      nonce: IERC20Permit(underlying).nonces(user),
      deadline: block.timestamp + 100
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      SigUtils.PERMIT_TYPEHASH,
      IERC20Permit(underlying).DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);
    IERC4626StataToken.SignatureParams memory sig = IERC4626StataToken.SignatureParams(v, r, s);
    vm.prank(user);
    uint256 shares = erc4626Upgradeable.depositWithPermit(
      env.amountToDeposit,
      receiver,
      permit.deadline,
      sig,
      true
    );

    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
    assertEq(IERC20(aToken).balanceOf(address(erc4626Upgradeable)), env.actualAmountToDeposit);
    assertEq(IERC20(underlying).balanceOf(user), env.underlyingBalance - env.actualAmountToDeposit);
  }

  function test_depositWithPermit_aToken(
    uint128 unboundedAssets,
    uint256 unboundedAmountToDeposit,
    address receiver
  ) external {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(unboundedAssets, unboundedAmountToDeposit);
    _fundAToken(env.underlyingBalance, user);

    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: address(erc4626Upgradeable),
      value: env.amountToDeposit,
      nonce: IERC20Permit(aToken).nonces(user),
      deadline: block.timestamp + 100
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      SigUtils.PERMIT_TYPEHASH,
      IERC20Permit(aToken).DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);
    IERC4626StataToken.SignatureParams memory sig = IERC4626StataToken.SignatureParams(v, r, s);
    vm.prank(user);
    uint256 shares = erc4626Upgradeable.depositWithPermit(
      env.amountToDeposit,
      receiver,
      permit.deadline,
      sig,
      false
    );

    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
    assertEq(IERC20(aToken).balanceOf(address(erc4626Upgradeable)), env.actualAmountToDeposit);
    assertEq(IERC20(aToken).balanceOf(user), env.underlyingBalance - env.actualAmountToDeposit);
  }

  // ### REDEEM TESTS ###
  function test_redeemATokens(uint256 assets, address receiver) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    vm.prank(user);
    uint256 redeemedAssets = erc4626Upgradeable.redeemATokens(shares, receiver, user);

    assertEq(erc4626Upgradeable.balanceOf(user), 0);
    assertEq(IERC20(aToken).balanceOf(receiver), redeemedAssets);
  }

  function test_redeemATokens_onBehalf_shouldRevert_insufficientAllowance(
    uint256 assets,
    uint256 allowance
  ) external {
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    allowance = bound(allowance, 0, shares - 1);
    vm.prank(user);
    erc4626Upgradeable.approve(address(this), allowance);

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector,
        address(this),
        allowance,
        env.underlyingBalance
      )
    );
    erc4626Upgradeable.redeemATokens(env.underlyingBalance, address(this), user);
  }

  function test_redeemATokens_onBehalf(uint256 assets) external {
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    vm.prank(user);
    erc4626Upgradeable.approve(address(this), shares);
    uint256 redeemedAssets = erc4626Upgradeable.redeemATokens(shares, address(this), user);

    assertEq(erc4626Upgradeable.balanceOf(user), 0);
    assertEq(IERC20(aToken).balanceOf(address(this)), redeemedAssets);
  }

  function test_redeem(uint256 assets, address receiver) external {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    vm.prank(user);
    uint256 redeemedAssets = erc4626Upgradeable.redeem(shares, receiver, user);
    assertEq(erc4626Upgradeable.balanceOf(user), 0);
    assertLe(IERC20(underlying).balanceOf(receiver), redeemedAssets);
  }

  // ### withdraw TESTS ###
  function test_withdraw(uint256 assets, address receiver) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    vm.prank(user);
    uint256 withdrawnShares = erc4626Upgradeable.withdraw(env.underlyingBalance, receiver, user);
    assertEq(withdrawnShares, shares);
    assertEq(erc4626Upgradeable.balanceOf(user), 0);
    assertLe(IERC20(underlying).balanceOf(receiver), env.underlyingBalance);
    assertApproxEqAbs(IERC20(underlying).balanceOf(receiver), env.underlyingBalance, 1);
  }

  function test_withdraw_shouldRevert_moreThenAvailable(uint256 assets, address receiver) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    _fund4626(env.underlyingBalance, user);

    vm.prank(user);
    vm.expectRevert(
      abi.encodeWithSelector(
        ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector,
        address(user),
        env.underlyingBalance + 1,
        env.underlyingBalance
      )
    );
    erc4626Upgradeable.withdraw(env.underlyingBalance + 1, receiver, user);
  }

  // ### mint TESTS ###
  function test_mint(uint256 assets, address receiver) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    _fundUnderlying(env.underlyingBalance, user);

    vm.startPrank(user);
    IERC20(underlying).approve(address(erc4626Upgradeable), env.underlyingBalance);
    uint256 shares = erc4626Upgradeable.previewDeposit(env.underlyingBalance);
    uint256 assetsUsedForMinting = erc4626Upgradeable.mint(shares, receiver);
    assertEq(assetsUsedForMinting, env.underlyingBalance);
    assertEq(erc4626Upgradeable.balanceOf(receiver), shares);
  }

  function test_mint_shouldRevert_mintMoreThenBalance(uint256 assets, address receiver) public {
    _validateReceiver(receiver);
    TestEnv memory env = _setupTestEnv(assets);
    _fundUnderlying(env.underlyingBalance, user);

    vm.startPrank(user);
    IERC20(underlying).approve(address(erc4626Upgradeable), type(uint256).max);
    uint256 shares = erc4626Upgradeable.previewDeposit(env.underlyingBalance);

    vm.expectRevert();
    erc4626Upgradeable.mint(shares + 1, receiver);
  }

  // ### maxDeposit TESTS ###
  function test_maxDeposit_freeze() public {
    vm.prank(roleList.marketOwner);
    contracts.poolConfiguratorProxy.setReserveFreeze(underlying, true);

    uint256 max = erc4626Upgradeable.maxDeposit(address(0));

    assertEq(max, 0);
  }

  function test_maxDeposit_paused() public {
    vm.prank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setReservePause(underlying, true);

    uint256 max = erc4626Upgradeable.maxDeposit(address(0));

    assertEq(max, 0);
  }

  function test_maxDeposit_noCap() public {
    vm.prank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setSupplyCap(underlying, 0);

    uint256 maxDeposit = erc4626Upgradeable.maxDeposit(address(0));
    uint256 maxMint = erc4626Upgradeable.maxMint(address(0));

    assertEq(maxDeposit, type(uint256).max);
    assertEq(maxMint, type(uint256).max);
  }

  function test_maxDeposit_cap(uint256 cap) public {
    cap = bound(cap, 1, type(uint32).max);
    vm.prank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setSupplyCap(underlying, cap);

    uint256 max = erc4626Upgradeable.maxDeposit(address(0));
    assertEq(max, cap * 10 ** erc4626Upgradeable.decimals());
  }

  // TODO: perhaps makes sense to add maxDeposit test with accruedToTreasury etc

  // ### maxRedeem TESTS ###
  function test_maxRedeem_paused(uint128 assets) public {
    TestEnv memory env = _setupTestEnv(assets);
    _fund4626(env.underlyingBalance, user);

    vm.prank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setReservePause(underlying, true);

    uint256 max = erc4626Upgradeable.maxRedeem(address(user));

    assertEq(max, 0);
  }

  function test_maxRedeem_sufficientAvailableLiquidity(uint128 assets) public {
    TestEnv memory env = _setupTestEnv(assets);
    uint256 shares = _fund4626(env.underlyingBalance, user);

    uint256 max = erc4626Upgradeable.maxRedeem(address(user));

    assertEq(max, shares);
  }

  function test_maxRedeem_inSufficientAvailableLiquidity(uint256 amountToBorrow) public {
    uint128 assets = 1e8;
    amountToBorrow = bound(amountToBorrow, 1, assets);
    _fund4626(assets, user);

    // borrow out some assets
    address borrowUser = address(99);
    vm.startPrank(borrowUser);
    deal(address(weth), borrowUser, 2_000 ether);
    weth.approve(address(contracts.poolProxy), 2_000 ether);
    contracts.poolProxy.deposit(address(weth), 2_000 ether, borrowUser, 0);
    contracts.poolProxy.borrow(underlying, amountToBorrow, 2, 0, borrowUser);

    uint256 max = erc4626Upgradeable.maxRedeem(address(user));

    assertEq(max, erc4626Upgradeable.previewRedeem(assets - amountToBorrow));
  }

  // ### lastestAnswer TESTS ###
  function test_latestAnswer_priceShouldBeEqualOnDefaultIndex() public {
    vm.mockCall(
      address(contracts.poolProxy),
      abi.encodeWithSelector(IPool.getReserveNormalizedIncome.selector),
      abi.encode(1e27)
    );
    uint256 stataPrice = uint256(erc4626Upgradeable.latestAnswer());
    uint256 underlyingPrice = contracts.aaveOracle.getAssetPrice(underlying);
    assertEq(stataPrice, underlyingPrice);
  }

  function test_latestAnswer_priceShouldReflectIndexAccrual(uint256 liquidityIndex) public {
    liquidityIndex = bound(liquidityIndex, 1e27, 1e29);
    vm.mockCall(
      address(contracts.poolProxy),
      abi.encodeWithSelector(IPool.getReserveNormalizedIncome.selector),
      abi.encode(liquidityIndex)
    );
    uint256 stataPrice = uint256(erc4626Upgradeable.latestAnswer());
    uint256 underlyingPrice = contracts.aaveOracle.getAssetPrice(underlying);
    uint256 expectedStataPrice = (underlyingPrice * liquidityIndex) / 1e27;
    assertEq(stataPrice, expectedStataPrice);

    // reverse the math to ensure precision loss is within bounds
    uint256 reversedUnderlying = (stataPrice * 1e27) / liquidityIndex;
    assertApproxEqAbs(underlyingPrice, reversedUnderlying, 1);
  }

  struct TestEnv {
    uint256 underlyingBalance;
    uint256 amountToDeposit;
    uint256 actualAmountToDeposit;
  }

  function _validateReceiver(address receiver) internal view {
    vm.assume(receiver != address(0) && receiver != address(aToken));
  }

  function _setupTestEnv(
    uint256 underlyingBalance,
    uint256 amountToDeposit
  ) internal pure returns (TestEnv memory) {
    TestEnv memory env;
    env.underlyingBalance = bound(underlyingBalance, 1, type(uint96).max);
    env.amountToDeposit = bound(amountToDeposit, 1, type(uint256).max);
    env.actualAmountToDeposit = env.amountToDeposit > env.underlyingBalance
      ? env.underlyingBalance
      : env.amountToDeposit;
    return env;
  }

  function _setupTestEnv(uint256 underlyingBalance) internal pure returns (TestEnv memory) {
    return _setupTestEnv(underlyingBalance, underlyingBalance);
  }

  function _fundUnderlying(uint256 assets, address receiver) internal {
    deal(underlying, receiver, assets);
  }

  function _fundAToken(uint256 assets, address receiver) internal {
    _fundUnderlying(assets, receiver);
    vm.startPrank(receiver);
    IERC20(underlying).approve(address(contracts.poolProxy), assets);
    contracts.poolProxy.deposit(underlying, assets, receiver, 0);
    vm.stopPrank();
  }

  function _fund4626(uint256 assets, address receiver) internal returns (uint256) {
    _fundAToken(assets, receiver);
    vm.startPrank(receiver);
    IERC20(aToken).approve(address(erc4626Upgradeable), assets);
    uint256 shares = erc4626Upgradeable.depositATokens(assets, receiver);
    vm.stopPrank();
    return shares;
  }
}

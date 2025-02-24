// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ParaSwapLiquiditySwapAdapter} from '../../../src/contracts/extensions/paraswap-adapters/ParaSwapLiquiditySwapAdapter.sol';
import {ParaSwapRepayAdapter, IParaSwapAugustusRegistry} from '../../../src/contracts/extensions/paraswap-adapters/ParaSwapRepayAdapter.sol';
import {ParaSwapWithdrawSwapAdapter} from '../../../src/contracts/extensions/paraswap-adapters/ParaSwapWithdrawSwapAdapter.sol';
import {BaseParaSwapAdapter} from '../../../src/contracts/extensions/paraswap-adapters/BaseParaSwapAdapter.sol';
import {IPool, DataTypes} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {MockParaSwapAugustus} from '../../../src/contracts/mocks/swap/MockParaSwapAugustus.sol';
import {MockParaSwapAugustusRegistry} from '../../../src/contracts/mocks/swap/MockParaSwapAugustusRegistry.sol';
import {IERC20Detailed} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

contract ParaswapAdaptersTest is TestnetProcedures {
  MockParaSwapAugustus internal mockParaSwapAugustus;
  MockParaSwapAugustusRegistry internal mockAugustusRegistry;
  ParaSwapLiquiditySwapAdapter internal paraSwapLiquiditySwapAdapter;
  ParaSwapRepayAdapter internal paraSwapRepayAdapter;
  ParaSwapWithdrawSwapAdapter internal paraSwapWithdrawSwapAdapter;

  IERC20Detailed internal aWETH;
  IERC20Detailed internal aUSDX;

  event Swapped(
    address indexed fromAsset,
    address indexed toAsset,
    uint256 fromAmount,
    uint256 receivedAmount
  );
  event Bought(
    address indexed fromAsset,
    address indexed toAsset,
    uint256 amountSold,
    uint256 receivedAmount
  );

  struct PermitSignature {
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function setUp() public {
    initTestEnvironment();
    mockParaSwapAugustus = new MockParaSwapAugustus();
    mockAugustusRegistry = new MockParaSwapAugustusRegistry(address(mockParaSwapAugustus));
    paraSwapLiquiditySwapAdapter = new ParaSwapLiquiditySwapAdapter(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IParaSwapAugustusRegistry(mockAugustusRegistry),
      carol
    );
    paraSwapRepayAdapter = new ParaSwapRepayAdapter(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IParaSwapAugustusRegistry(mockAugustusRegistry),
      carol
    );
    paraSwapWithdrawSwapAdapter = new ParaSwapWithdrawSwapAdapter(
      IPoolAddressesProvider(report.poolAddressesProvider),
      IParaSwapAugustusRegistry(mockAugustusRegistry),
      carol
    );

    aWETH = IERC20Detailed(contracts.poolProxy.getReserveAToken(tokenList.weth));
    aUSDX = IERC20Detailed(contracts.poolProxy.getReserveAToken(tokenList.usdx));

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockParaSwapAugustus));
  }

  function _seedMarket() internal {
    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.weth, 50e18, alice, 0);
    vm.stopPrank();
  }

  function _seedMarketRepay() internal {
    vm.startPrank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 100_000e6, carol, 0);
    contracts.poolProxy.supply(tokenList.weth, 100e18, carol, 0);
    vm.stopPrank();
    vm.startPrank(alice);
    contracts.poolProxy.supply(tokenList.weth, 100e18, alice, 0);
    vm.stopPrank();
  }

  function test_swap_liquidity_flashloan() public {
    _seedMarket();

    PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    uint256 flashloanPremium = (amountToSwap * 9) / 10000;
    uint256 flashloanTotal = amountToSwap + flashloanPremium;

    vm.prank(alice);
    aWETH.approve(address(paraSwapLiquiditySwapAdapter), flashloanTotal);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );
    bytes memory encodedInput = abi.encode(
      tokenList.usdx,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      emptyPermit
    );

    vm.expectEmit(address(paraSwapLiquiditySwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapLiquiditySwapAdapter),
      tokenList.weth,
      amountToSwap,
      encodedInput,
      0
    );
  }

  function test_swap_liquidity_permit_flashloan() public {
    _seedMarket();

    uint256 amountToSwap = 10 ether;
    uint256 flashloanTotal = amountToSwap + ((amountToSwap * 9) / 10000);
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapLiquiditySwapAdapter),
      value: flashloanTotal,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );
    bytes memory encodedInput = abi.encode(
      tokenList.usdx,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      permitInput
    );

    vm.expectEmit(address(paraSwapLiquiditySwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapLiquiditySwapAdapter),
      tokenList.weth,
      amountToSwap,
      encodedInput,
      0
    );
  }

  function test_reverts_offset_out_of_range_swap_liquidity_permit_flashloan() public {
    _seedMarket();

    uint256 amountToSwap = 51 ether;
    uint256 flashloanTotal = amountToSwap + ((amountToSwap * 9) / 10000);
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapLiquiditySwapAdapter),
      value: flashloanTotal,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );
    bytes memory encodedInput = abi.encode(
      tokenList.usdx,
      expectedUsdxAmount,
      2,
      augustusInput,
      address(mockParaSwapAugustus),
      permitInput
    );

    vm.expectRevert(bytes('FROM_AMOUNT_OFFSET_OUT_OF_RANGE'));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapLiquiditySwapAdapter),
      tokenList.weth,
      amountToSwap,
      encodedInput,
      0
    );
  }

  function test_swapAndDeposit() public {
    _seedMarket();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapLiquiditySwapAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectEmit(address(paraSwapLiquiditySwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    paraSwapLiquiditySwapAdapter.swapAndDeposit(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      emptyPermit
    );
  }

  function test_swapAndDeposit_permit() public {
    _seedMarket();

    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapLiquiditySwapAdapter),
      value: amountToSwap,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    BaseParaSwapAdapter.PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapLiquiditySwapAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectEmit(address(paraSwapLiquiditySwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    paraSwapLiquiditySwapAdapter.swapAndDeposit(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      permitInput
    );
  }

  function test_reverts_swapAndDeposit_offset() public {
    _seedMarket();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 51 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapLiquiditySwapAdapter), UINT256_MAX);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectRevert(bytes('FROM_AMOUNT_OFFSET_OUT_OF_RANGE'));

    vm.prank(alice);
    paraSwapLiquiditySwapAdapter.swapAndDeposit(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      amountToSwap,
      augustusInput,
      address(mockParaSwapAugustus),
      emptyPermit
    );
  }

  function test_swapAndRepay() public {
    _seedMarketRepay();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapRepayAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory params = abi.encode(augustusInput, address(mockParaSwapAugustus));

    vm.expectEmit(address(paraSwapRepayAdapter));
    emit Bought(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    paraSwapRepayAdapter.swapAndRepay(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      2,
      0,
      params,
      emptyPermit
    );
  }

  function test_swapAndRepay_no_collateral_leftovers() public {
    _seedMarketRepay();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap - 1 ether,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapRepayAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory params = abi.encode(augustusInput, address(mockParaSwapAugustus));

    vm.expectEmit(address(paraSwapRepayAdapter));
    emit Bought(tokenList.weth, tokenList.usdx, 9 ether, expectedUsdxAmount);

    vm.prank(alice);
    paraSwapRepayAdapter.swapAndRepay(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      2,
      0,
      params,
      emptyPermit
    );

    assertEq(aWETH.balanceOf(address(paraSwapRepayAdapter)), 0);
  }

  function test_swapAndRepay_permit() public {
    _seedMarketRepay();

    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapRepayAdapter),
      value: amountToSwap,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    BaseParaSwapAdapter.PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapRepayAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory params = abi.encode(augustusInput, address(mockParaSwapAugustus));

    vm.expectEmit(address(paraSwapRepayAdapter));
    emit Bought(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    paraSwapRepayAdapter.swapAndRepay(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      2,
      0,
      params,
      permitInput
    );
  }

  function test_swapAndRepay_flashloan() public {
    _seedMarketRepay();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 approvalAmount = 10 ether + ((10 ether * 9) / 100_00);
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapRepayAdapter), approvalAmount);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory augustusParams = abi.encode(augustusInput, address(mockParaSwapAugustus));

    bytes memory flashLoanParams = abi.encode(
      tokenList.usdx,
      expectedUsdxAmount,
      0,
      2,
      augustusParams,
      emptyPermit
    );

    vm.expectEmit(address(paraSwapRepayAdapter));
    emit Bought(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapRepayAdapter),
      tokenList.weth,
      amountToSwap,
      flashLoanParams,
      0
    );
  }

  function test_swapAndRepay_flashloan_permit() public {
    _seedMarketRepay();

    uint256 amountToSwap = 10 ether;
    uint256 approvalAmount = 10 ether + ((10 ether * 9) / 100_00);
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapRepayAdapter),
      value: approvalAmount,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    BaseParaSwapAdapter.PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory augustusParams = abi.encode(augustusInput, address(mockParaSwapAugustus));

    bytes memory flashLoanParams = abi.encode(
      tokenList.usdx,
      expectedUsdxAmount,
      0,
      2,
      augustusParams,
      permitInput
    );

    vm.expectEmit(address(paraSwapRepayAdapter));
    emit Bought(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapRepayAdapter),
      tokenList.weth,
      amountToSwap,
      flashLoanParams,
      0
    );
  }

  function test_reverts_swapAndRepay_offset_out_of_range() public {
    _seedMarketRepay();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 10 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.prank(alice);
    contracts.poolProxy.borrow(tokenList.usdx, expectedUsdxAmount, 2, 0, alice);

    mockParaSwapAugustus.expectBuy(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount,
      expectedUsdxAmount
    );

    vm.prank(alice);
    aWETH.approve(address(paraSwapRepayAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.buy.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    bytes memory params = abi.encode(augustusInput, address(mockParaSwapAugustus));

    vm.expectRevert(bytes('TO_AMOUNT_OFFSET_OUT_OF_RANGE'));

    vm.prank(alice);
    paraSwapRepayAdapter.swapAndRepay(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      2,
      1,
      params,
      emptyPermit
    );
  }

  function test_withdrawAndSwap() public {
    _seedMarket();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 50 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.startPrank(alice);
    aWETH.approve(address(paraSwapWithdrawSwapAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectEmit(address(paraSwapWithdrawSwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    paraSwapWithdrawSwapAdapter.withdrawAndSwap(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      emptyPermit
    );

    vm.stopPrank();
  }

  function test_withdrawAndSwap_permit() public {
    _seedMarket();

    uint256 amountToSwap = 50 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: address(paraSwapWithdrawSwapAdapter),
      value: amountToSwap,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aWETH.name()),
      bytes('1'),
      address(aWETH)
    );

    BaseParaSwapAdapter.PermitSignature memory permitInput;
    permitInput.amount = permit.value;
    permitInput.deadline = permit.deadline;

    (permitInput.v, permitInput.r, permitInput.s) = vm.sign(alicePrivateKey, digest);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectEmit(address(paraSwapWithdrawSwapAdapter));
    emit Swapped(tokenList.weth, tokenList.usdx, amountToSwap, expectedUsdxAmount);

    vm.startPrank(alice);

    paraSwapWithdrawSwapAdapter.withdrawAndSwap(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      0,
      augustusInput,
      address(mockParaSwapAugustus),
      permitInput
    );

    vm.stopPrank();
  }

  function test_reverts_withdrawAndSwap_offset_out_of_range() public {
    _seedMarket();

    BaseParaSwapAdapter.PermitSignature memory emptyPermit;
    uint256 amountToSwap = 50 ether;
    uint256 usdxPrice = 1e8;
    uint256 expectedUsdxAmount = amountToSwap / usdxPrice;

    vm.startPrank(alice);
    aWETH.approve(address(paraSwapWithdrawSwapAdapter), amountToSwap);

    bytes memory augustusInput = abi.encodeWithSelector(
      mockParaSwapAugustus.swap.selector,
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      expectedUsdxAmount
    );

    mockParaSwapAugustus.expectSwap(
      tokenList.weth,
      tokenList.usdx,
      amountToSwap,
      amountToSwap,
      expectedUsdxAmount
    );

    vm.expectRevert(bytes('FROM_AMOUNT_OFFSET_OUT_OF_RANGE'));

    paraSwapWithdrawSwapAdapter.withdrawAndSwap(
      IERC20Detailed(tokenList.weth),
      IERC20Detailed(tokenList.usdx),
      amountToSwap,
      expectedUsdxAmount,
      amountToSwap,
      augustusInput,
      address(mockParaSwapAugustus),
      emptyPermit
    );

    vm.stopPrank();
  }

  function test_withdrawSwapAdapter_reverts_flashloan() public {
    _seedMarket();

    vm.prank(alice);
    vm.expectRevert('NOT_SUPPORTED');
    contracts.poolProxy.flashLoanSimple(
      address(paraSwapWithdrawSwapAdapter),
      tokenList.weth,
      1 ether,
      '',
      0
    );
  }

  function test_rescueTokens() public {
    deal(tokenList.usdx, address(paraSwapRepayAdapter), 100e6);

    uint256 balanceBefore = usdx.balanceOf(carol);

    vm.prank(carol);
    paraSwapRepayAdapter.rescueTokens(IERC20Detailed(tokenList.usdx));

    assertEq(usdx.balanceOf(carol), balanceBefore + 100e6);
  }
}

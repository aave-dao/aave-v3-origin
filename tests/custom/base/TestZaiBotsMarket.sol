// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2, StdUtils} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPoolConfigurator} from '../../../src/contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IACLManager} from '../../../src/contracts/interfaces/IACLManager.sol';
import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {IVariableDebtToken} from '../../../src/contracts/interfaces/IVariableDebtToken.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

import {JUBCToken} from 'custom/jubc/JUBCToken.sol';
import {JpyUbiAMOMinter} from 'custom/amo/JpyUbiAMOMinter.sol';
import {JpyUbiConvexAMO} from 'custom/amo/JpyUbiConvexAMO.sol';
import {DataStreamAggregatorAdapter} from 'custom/oracles/DataStreamAggregatorAdapter.sol';

/**
 * @title TestZaiBotsMarket
 * @notice Base test contract for all UBC Market tests
 * @dev Provides deployment/connection to all protocol contracts and helper functions
 */
abstract contract TestZaiBotsMarket is Test {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // ══════════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════════

  uint256 constant WAD = 1e18;
  uint256 constant RAY = 1e27;
  uint256 constant BPS = 1e4;
  uint256 constant USD_DECIMALS = 8;
  uint256 constant PRICE_PRECISION = 1e6;

  // Fuzzing bounds
  uint256 constant MIN_FUZZ_AMOUNT = 1e6;
  uint256 constant MAX_FUZZ_AMOUNT = 1e12 * WAD;
  uint256 constant MIN_FUZZ_TIME = 1 hours;
  uint256 constant MAX_FUZZ_TIME = 365 days;
  uint256 constant MIN_FUZZ_LTV = 100;
  uint256 constant MAX_FUZZ_LTV = 9500;

  // Default test amounts
  uint256 constant DEFAULT_MINT_AMOUNT = 1_000_000e18;
  uint256 constant DEFAULT_COLLATERAL_AMOUNT = 1_000_000e6;
  uint256 constant DEFAULT_LP_AMOUNT = 100_000e18;

  // Roles
  bytes32 constant FACILITATOR_MANAGER_ROLE = keccak256('FACILITATOR_MANAGER_ROLE');
  bytes32 constant BUCKET_MANAGER_ROLE = keccak256('BUCKET_MANAGER_ROLE');
  bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

  // Error codes from Aave
  string constant ERR_BORROWING_NOT_ENABLED = '30';
  string constant ERR_COLLATERAL_BALANCE_ZERO = '9';
  string constant ERR_HEALTH_FACTOR_BELOW_THRESHOLD = '10';
  string constant ERR_COLLATERAL_CANNOT_COVER_BORROW = '11';
  string constant ERR_FLASHLOAN_DISABLED = '93';
  string constant ERR_DEBT_CEILING_EXCEEDED = '85';
  string constant ERR_SUPPLY_CAP_EXCEEDED = '51';
  string constant ERR_BORROW_CAP_EXCEEDED = '52';

  // ══════════════════════════════════════════════════════════════════════════════
  // NETWORK-SPECIFIC ADDRESSES
  // ══════════════════════════════════════════════════════════════════════════════

  struct NetworkConfig {
    address poolAddressesProvider;
    address pool;
    address poolConfigurator;
    address aclManager;
    address oracle;
    address treasury;
    address jpyUbiToken;
    address jpyUbiAToken;
    address jpyUbiDebtToken;
    address usdc;
    address usdt;
    address cbBtc;
    address link;
    address virtuals;
    address fet;
    address render;
    address cusd;
    address jpyUsdFeed;
    address usdcUsdFeed;
    address usdtUsdFeed;
    address cbBtcUsdFeed;
    address linkUsdFeed;
    address uniV3Factory;
    address uniV3Router;
    address jpyUsdcPool;
    address amoController;
  }

  // Mainnet addresses
  NetworkConfig internal mainnetConfig =
    NetworkConfig({
      poolAddressesProvider: address(0),
      pool: address(0),
      poolConfigurator: address(0),
      aclManager: address(0),
      oracle: address(0),
      treasury: address(0),
      jpyUbiToken: address(0),
      jpyUbiAToken: address(0),
      jpyUbiDebtToken: address(0),
      usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
      usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
      cbBtc: 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf,
      link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
      virtuals: address(0),
      fet: 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85,
      render: 0x6De037ef9aD2725EB40118Bb1702EBb27e4Aeb24,
      cusd: address(0),
      jpyUsdFeed: 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3,
      usdcUsdFeed: 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6,
      usdtUsdFeed: 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D,
      cbBtcUsdFeed: 0x2665701293fCbEB223D11A08D826563EDcCE423A,
      linkUsdFeed: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c,
      uniV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
      uniV3Router: 0xE592427A0AEce92De3Edee1F18E0157C05861564,
      jpyUsdcPool: address(0),
      amoController: address(0)
    });

  // Base addresses
  NetworkConfig internal baseConfig =
    NetworkConfig({
      poolAddressesProvider: address(0),
      pool: address(0),
      poolConfigurator: address(0),
      aclManager: address(0),
      oracle: address(0),
      treasury: address(0),
      jpyUbiToken: address(0),
      jpyUbiAToken: address(0),
      jpyUbiDebtToken: address(0),
      usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
      usdt: 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2,
      cbBtc: 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf,
      link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
      virtuals: address(0),
      fet: address(0),
      render: address(0),
      cusd: address(0),
      jpyUsdFeed: address(0),
      usdcUsdFeed: 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B,
      usdtUsdFeed: 0xf19d560eB8d2ADf07BD6D13ed03e1D11215721F9,
      cbBtcUsdFeed: 0x07DA0E54543a844a80ABE69c8A12F22B3aA59f9D,
      linkUsdFeed: 0x17CAb8FE31E32f08326e5E27412894e49B0f9D65,
      uniV3Factory: 0x33128a8fC17869897dcE68Ed026d694621f6FDfD,
      uniV3Router: 0x2626664c2603336E57B271c5C0b26F421741e481,
      jpyUsdcPool: address(0),
      amoController: address(0)
    });

  // ══════════════════════════════════════════════════════════════════════════════
  // STATE VARIABLES - AAVE V3
  // ══════════════════════════════════════════════════════════════════════════════

  NetworkConfig public config;
  bool public isForked;
  uint256 public forkId;

  IPoolAddressesProvider public addressesProvider;
  IPool public pool;
  IPoolConfigurator public configurator;
  IACLManager public aclManager;
  IAaveOracle public oracle;

  JUBCToken public jpyUbi;
  JpyUbiAMOMinter public amoMinter;
  JpyUbiConvexAMO public convexAMO;
  DataStreamAggregatorAdapter public jpyUsdOracle;

  IAToken public jpyUbiAToken;
  IVariableDebtToken public jpyUbiDebtToken;

  IERC20 public usdt;
  IERC20 public cbBtc;
  IERC20 public link;
  IERC20 public virtuals;
  IERC20 public fet;
  IERC20 public render;
  IERC20 public cusd;

  MockERC20 public usdc;
  MockERC20 public threePoolToken;
  MockERC20 public crvToken;
  MockERC20 public cvxToken;
  MockERC20 public cvxCrvToken;
  MockCurveMetapool public curveMetapool;
  MockCurve3Pool public curve3Pool;
  MockCollateralPool public collateralPool;
  MockVerifierProxy public verifierProxy;
  MockConvexBooster public convexBooster;
  MockConvexBaseRewardPool public convexBaseRewardPool;
  MockConvexClaimZap public convexClaimZap;
  MockCvxRewardPool public cvxRewardPool;

  // ══════════════════════════════════════════════════════════════════════════════
  // TEST ACTORS
  // ══════════════════════════════════════════════════════════════════════════════

  address public admin;
  address public owner;
  address public treasury;
  address public timelock;
  address public custodian;
  address public alice;
  address public bob;
  address public charlie;
  address public keeper;
  address public attacker;

  address[] public collateralAssets;
  string[] public collateralSymbols;

  uint256 public initialJpyUbiSupply;
  uint256 public initialCollateralBalance;

  // ══════════════════════════════════════════════════════════════════════════════
  // EVENTS
  // ══════════════════════════════════════════════════════════════════════════════

  event Deposit(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 amount);
  event Repay(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public virtual {
    admin = makeAddr('admin');
    owner = makeAddr('owner');
    treasury = makeAddr('treasury');
    timelock = makeAddr('timelock');
    custodian = makeAddr('custodian');
    alice = makeAddr('alice');
    bob = makeAddr('bob');
    charlie = makeAddr('charlie');
    keeper = makeAddr('keeper');
    attacker = makeAddr('attacker');

    vm.deal(admin, 100 ether);
    vm.deal(owner, 100 ether);
    vm.deal(alice, 100 ether);
    vm.deal(bob, 100 ether);
    vm.deal(charlie, 100 ether);
    vm.deal(keeper, 10 ether);
    vm.deal(attacker, 100 ether);

    string memory network = vm.envOr('NETWORK', string('local'));

    if (keccak256(bytes(network)) == keccak256(bytes('mainnet'))) {
      _setupFork('mainnet');
      config = mainnetConfig;
    } else if (keccak256(bytes(network)) == keccak256(bytes('base'))) {
      _setupFork('base');
      config = baseConfig;
    } else {
      _setupLocal();
    }

    vm.startPrank(owner);
    _setupRoles();
    vm.stopPrank();

    _initializeCollateralArrays();
    _labelAddresses();
  }

  function _setupFork(string memory network) internal {
    string memory rpcUrl;
    if (keccak256(bytes(network)) == keccak256(bytes('mainnet'))) {
      rpcUrl = vm.envOr('ETH_RPC_URL', string(''));
    } else if (keccak256(bytes(network)) == keccak256(bytes('base'))) {
      rpcUrl = vm.envOr('BASE_RPC_URL', string(''));
    }

    require(bytes(rpcUrl).length > 0, 'RPC URL not set');

    forkId = vm.createFork(rpcUrl);
    vm.selectFork(forkId);
    isForked = true;

    _connectToDeployedContracts();
  }

  function _setupLocal() internal virtual {
    isForked = false;

    vm.startPrank(owner);

    usdc = new MockERC20('USD Coin', 'USDC', 6);
    threePoolToken = new MockERC20('Curve.fi DAI/USDC/USDT', '3Crv', 18);

    curve3Pool = new MockCurve3Pool(address(usdc), address(threePoolToken));
    curveMetapool = new MockCurveMetapool(address(threePoolToken));

    collateralPool = new MockCollateralPool(address(usdc));

    verifierProxy = new MockVerifierProxy();

    jpyUbi = new JUBCToken(owner);

    jpyUsdOracle = new DataStreamAggregatorAdapter(address(verifierProxy), keccak256('JPY/USD'), 8, 'JPY / USD');

    vm.stopPrank();

    _fundAccounts();

    initialJpyUbiSupply = jpyUbi.totalSupply();
    initialCollateralBalance = usdc.balanceOf(address(collateralPool));
  }

  function _setupRoles() internal virtual {
    jpyUbi.grantRole(FACILITATOR_MANAGER_ROLE, owner);
    jpyUbi.grantRole(BUCKET_MANAGER_ROLE, owner);

    jpyUsdOracle.setKeeperAuthorization(keeper, true);
  }

  function _fundAccounts() internal {
    usdc.mint(alice, 10_000_000e6);
    usdc.mint(bob, 10_000_000e6);
    usdc.mint(charlie, 10_000_000e6);
    usdc.mint(address(collateralPool), 100_000_000e6);
  }

  function _connectToDeployedContracts() internal {
    if (config.poolAddressesProvider != address(0)) {
      addressesProvider = IPoolAddressesProvider(config.poolAddressesProvider);
      pool = IPool(addressesProvider.getPool());
      configurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
      aclManager = IACLManager(addressesProvider.getACLManager());
      oracle = IAaveOracle(addressesProvider.getPriceOracle());
    }

    if (config.jpyUbiToken != address(0)) {
      jpyUbi = JUBCToken(config.jpyUbiToken);
    }
    if (config.usdc != address(0)) usdc = MockERC20(config.usdc);
    if (config.usdt != address(0)) usdt = IERC20(config.usdt);
    if (config.cbBtc != address(0)) cbBtc = IERC20(config.cbBtc);
    if (config.link != address(0)) link = IERC20(config.link);
    if (config.virtuals != address(0)) virtuals = IERC20(config.virtuals);
    if (config.fet != address(0)) fet = IERC20(config.fet);
    if (config.render != address(0)) render = IERC20(config.render);
    if (config.cusd != address(0)) cusd = IERC20(config.cusd);
  }

  function _initializeCollateralArrays() internal {
    if (address(usdc) != address(0)) {
      collateralAssets.push(address(usdc));
      collateralSymbols.push('USDC');
    }
    if (address(usdt) != address(0)) {
      collateralAssets.push(address(usdt));
      collateralSymbols.push('USDT');
    }
    if (address(cbBtc) != address(0)) {
      collateralAssets.push(address(cbBtc));
      collateralSymbols.push('cbBTC');
    }
    if (address(link) != address(0)) {
      collateralAssets.push(address(link));
      collateralSymbols.push('LINK');
    }
  }

  function _labelAddresses() internal {
    vm.label(admin, 'Admin');
    vm.label(owner, 'Owner');
    vm.label(treasury, 'Treasury');
    vm.label(timelock, 'Timelock');
    vm.label(custodian, 'Custodian');
    vm.label(alice, 'Alice');
    vm.label(bob, 'Bob');
    vm.label(charlie, 'Charlie');
    vm.label(keeper, 'Keeper');
    vm.label(attacker, 'Attacker');

    if (address(pool) != address(0)) vm.label(address(pool), 'Pool');
    if (address(jpyUbi) != address(0)) vm.label(address(jpyUbi), 'JUBCToken');
    if (address(amoMinter) != address(0)) vm.label(address(amoMinter), 'AMOMinter');
    if (address(convexAMO) != address(0)) vm.label(address(convexAMO), 'ConvexAMO');
    if (address(jpyUsdOracle) != address(0)) vm.label(address(jpyUsdOracle), 'JpyUsdOracle');
    if (address(usdc) != address(0)) vm.label(address(usdc), 'USDC');
    if (address(usdt) != address(0)) vm.label(address(usdt), 'USDT');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - AAVE V3 DEPOSITS
  // ══════════════════════════════════════════════════════════════════════════════

  function _deposit(address user, address asset, uint256 amount) internal {
    require(address(pool) != address(0), 'Pool not initialized');

    vm.startPrank(user);
    IERC20(asset).approve(address(pool), amount);
    pool.supply(asset, amount, user, 0);
    vm.stopPrank();
  }

  function _depositFuzzed(address user, address asset, uint256 amount) internal returns (uint256 boundedAmount) {
    uint8 decimals = _getDecimals(asset);
    uint256 minAmount = 10 ** (decimals > 6 ? decimals - 6 : 0);
    uint256 maxAmount = 10 ** (decimals + 6);

    boundedAmount = bound(amount, minAmount, maxAmount);

    deal(asset, user, boundedAmount);
    _deposit(user, asset, boundedAmount);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - AAVE V3 BORROWING
  // ══════════════════════════════════════════════════════════════════════════════

  function _borrow(address user, uint256 amount) internal {
    require(address(pool) != address(0), 'Pool not initialized');
    require(address(jpyUbi) != address(0), 'jpyUBI not initialized');

    vm.prank(user);
    pool.borrow(address(jpyUbi), amount, 2, 0, user);
  }

  function _borrowFuzzed(address user, uint256 borrowAmount) internal returns (uint256 boundedAmount) {
    (, , uint256 availableBorrowsBase, , , ) = pool.getUserAccountData(user);

    uint256 jpyUbiPrice = oracle.getAssetPrice(address(jpyUbi));
    uint256 maxBorrow = (availableBorrowsBase * WAD) / jpyUbiPrice;

    boundedAmount = bound(borrowAmount, WAD, (maxBorrow * 99) / 100);
    _borrow(user, boundedAmount);
  }

  function _repay(address user, uint256 amount) internal {
    require(address(pool) != address(0), 'Pool not initialized');

    vm.startPrank(user);
    jpyUbi.approve(address(pool), amount);
    pool.repay(address(jpyUbi), amount, 2, user);
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - ASSERTIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function _getHealthFactor(address user) internal view virtual returns (uint256) {
    (, , , , , uint256 healthFactor) = pool.getUserAccountData(user);
    return healthFactor;
  }

  function _assertHealthFactorAbove(address user, uint256 minHF) internal view virtual {
    uint256 hf = _getHealthFactor(user);
    assertGe(hf, minHF, 'Health factor below minimum');
  }

  function _assertNoDebt(address user) internal view virtual {
    (, uint256 totalDebtBase, , , , ) = pool.getUserAccountData(user);
    assertEq(totalDebtBase, 0, 'User should have no debt');
  }

  function _assertNoCollateral(address user) internal view virtual {
    (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(user);
    assertEq(totalCollateralBase, 0, 'User should have no collateral');
  }

  function _getTotalCollateralUSD(address user) internal view virtual returns (uint256) {
    (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(user);
    return totalCollateralBase;
  }

  function _getTotalDebtUSD(address user) internal view virtual returns (uint256) {
    (, uint256 totalDebtBase, , , , ) = pool.getUserAccountData(user);
    return totalDebtBase;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - RESERVE CONFIG
  // ══════════════════════════════════════════════════════════════════════════════

  function _isBorrowingEnabled(address asset) internal view virtual returns (bool) {
    DataTypes.ReserveConfigurationMap memory reserveConfig = pool.getConfiguration(asset);
    return reserveConfig.getBorrowingEnabled();
  }

  function _isFlashLoanEnabled(address asset) internal view virtual returns (bool) {
    DataTypes.ReserveConfigurationMap memory reserveConfig = pool.getConfiguration(asset);
    return reserveConfig.getFlashLoanEnabled();
  }

  function _getLTV(address asset) internal view virtual returns (uint256) {
    DataTypes.ReserveConfigurationMap memory reserveConfig = pool.getConfiguration(asset);
    return reserveConfig.getLtv();
  }

  function _getLiquidationThreshold(address asset) internal view virtual returns (uint256) {
    DataTypes.ReserveConfigurationMap memory reserveConfig = pool.getConfiguration(asset);
    return reserveConfig.getLiquidationThreshold();
  }

  function _getDebtCeiling(address asset) internal view virtual returns (uint256) {
    DataTypes.ReserveConfigurationMap memory reserveConfig = pool.getConfiguration(asset);
    return reserveConfig.getDebtCeiling();
  }

  function _isIsolationMode(address asset) internal view virtual returns (bool) {
    return _getDebtCeiling(asset) > 0;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - JPYUBI SPECIFIC
  // ══════════════════════════════════════════════════════════════════════════════

  function _getFacilitatorBucket(address facilitator) internal view virtual returns (uint256 capacity, uint256 level) {
    return jpyUbi.getFacilitatorBucket(facilitator);
  }

  function _getJpyUbiTotalSupply() internal view virtual returns (uint256) {
    return jpyUbi.totalSupply();
  }

  function _isFacilitator(address account) internal view virtual returns (bool) {
    JUBCToken.Facilitator memory f = jpyUbi.getFacilitator(account);
    return bytes(f.label).length > 0;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // INVARIANT CHECK FUNCTIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function checkProtocolInvariants() internal view virtual returns (bool success) {
    _invariant_jpyUbiNotCollateral();
    _invariant_onlyJpyUbiBorrowable();
    _invariant_noFlashLoans();
    _invariant_facilitatorBucketRespected();
  }

  function _invariant_jpyUbiNotCollateral() internal view virtual {
    if (address(jpyUbi) == address(0) || address(pool) == address(0)) return;
    assertEq(_getLTV(address(jpyUbi)), 0, 'INVARIANT: jpyUBI LTV must be 0');
  }

  function _invariant_onlyJpyUbiBorrowable() internal view virtual {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      assertFalse(
        _isBorrowingEnabled(collateralAssets[i]),
        string.concat('INVARIANT: ', collateralSymbols[i], ' must not be borrowable')
      );
    }

    if (address(jpyUbi) != address(0)) {
      assertTrue(_isBorrowingEnabled(address(jpyUbi)), 'INVARIANT: jpyUBI must be borrowable');
    }
  }

  function _invariant_noFlashLoans() internal view virtual {
    if (address(pool) == address(0)) return;

    for (uint256 i = 0; i < collateralAssets.length; i++) {
      assertFalse(
        _isFlashLoanEnabled(collateralAssets[i]),
        string.concat('INVARIANT: ', collateralSymbols[i], ' flash loans must be disabled')
      );
    }

    if (address(jpyUbi) != address(0)) {
      assertFalse(_isFlashLoanEnabled(address(jpyUbi)), 'INVARIANT: jpyUBI flash loans must be disabled');
    }
  }

  function _invariant_facilitatorBucketRespected() internal view virtual {
    if (address(jpyUbiAToken) == address(0)) return;

    (uint256 capacity, uint256 level) = _getFacilitatorBucket(address(jpyUbiAToken));
    assertLe(level, capacity, 'INVARIANT: Facilitator bucket level must not exceed capacity');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS - UTILITIES
  // ══════════════════════════════════════════════════════════════════════════════

  function _getDecimals(address token) internal view virtual returns (uint8) {
    try IERC20Metadata(token).decimals() returns (uint8 decimals) {
      return decimals;
    } catch {
      return 18;
    }
  }

  function _warpTime(uint256 seconds_) internal {
    vm.warp(block.timestamp + seconds_);
  }

  function _warpTimeFuzzed(uint256 time) internal returns (uint256 boundedTime) {
    boundedTime = bound(time, MIN_FUZZ_TIME, MAX_FUZZ_TIME);
    _warpTime(boundedTime);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MODIFIERS FOR FUZZING
  // ══════════════════════════════════════════════════════════════════════════════

  modifier boundAmount(uint256 amount, uint256 min, uint256 max) {
    amount = bound(amount, min, max);
    _;
  }

  modifier validAddress(address addr) {
    vm.assume(addr != address(0));
    vm.assume(addr.code.length == 0);
    vm.assume(addr != admin && addr != treasury);
    _;
  }

  modifier withCollateral(address user, address asset, uint256 amount) {
    deal(asset, user, amount);
    _deposit(user, asset, amount);
    _;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // EVENT EXPECTATION HELPERS
  // ══════════════════════════════════════════════════════════════════════════════

  function expectRevertWithSelector(bytes4 selector) internal {
    vm.expectRevert(selector);
  }

  function expectRevertWithMessage(string memory message) internal {
    vm.expectRevert(bytes(message));
  }
}

// Interface for decimals
interface IERC20Metadata {
  function decimals() external view returns (uint8);
}

// ══════════════════════════════════════════════════════════════════════════════
// MOCK CONTRACTS
// ══════════════════════════════════════════════════════════════════════════════

contract MockERC20 is ERC20 {
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
    _decimals = decimals_;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    _burn(from, amount);
  }
}

contract MockCurve3Pool {
  address public usdc;
  address public lpToken;
  uint256 public virtualPrice = 1e18;

  constructor(address _usdc, address _lpToken) {
    usdc = _usdc;
    lpToken = _lpToken;
  }

  function get_virtual_price() external view returns (uint256) {
    return virtualPrice;
  }

  function setVirtualPrice(uint256 _price) external {
    virtualPrice = _price;
  }

  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external returns (uint256) {
    if (amounts[1] > 0) {
      IERC20(usdc).transferFrom(msg.sender, address(this), amounts[1]);
    }

    uint256 lpAmount = amounts[0] + amounts[1] * 1e12 + amounts[2];
    require(lpAmount >= min_mint_amount, 'Slippage');

    MockERC20(lpToken).mint(msg.sender, lpAmount);
    return lpAmount;
  }

  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external returns (uint256) {
    MockERC20(lpToken).burn(msg.sender, _token_amount);

    uint256 out = _token_amount;
    if (i == 1) {
      out = _token_amount / 1e12;
    }
    require(out >= min_amount, 'Slippage');

    if (i == 1) {
      MockERC20(usdc).mint(msg.sender, out);
    }
    return out;
  }
}

contract MockCurveMetapool {
  address public baseToken;
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  uint256 public virtualPrice = 1e18;

  constructor(address _baseToken) {
    baseToken = _baseToken;
  }

  function get_virtual_price() external view returns (uint256) {
    return virtualPrice;
  }

  function get_dy(int128, int128, uint256 dx, uint256[2] memory) external pure returns (uint256) {
    return dx;
  }

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256) {
    uint256 lpAmount = amounts[0] + amounts[1];
    require(lpAmount >= min_mint_amount, 'Slippage');

    balanceOf[msg.sender] += lpAmount;
    totalSupply += lpAmount;

    return lpAmount;
  }

  function remove_liquidity_one_coin(uint256 _token_amount, int128, uint256 min_amount) external returns (uint256) {
    require(balanceOf[msg.sender] >= _token_amount, 'Insufficient balance');

    balanceOf[msg.sender] -= _token_amount;
    totalSupply -= _token_amount;

    require(_token_amount >= min_amount, 'Slippage');
    return _token_amount;
  }

  function approve(address, uint256) external returns (bool) {
    return true;
  }
}

contract MockCollateralPool {
  address public collateral;
  mapping(address => uint256) public collateralAddrToIdx;

  constructor(address _collateral) {
    collateral = _collateral;
    collateralAddrToIdx[_collateral] = 1;
  }

  function amoMinterBorrow(uint256 collat_amount) external {
    IERC20(collateral).transfer(msg.sender, collat_amount);
  }
}

contract MockVerifierProxy {
  int192 public mockPrice;

  function setMockPrice(int192 _price) external {
    mockPrice = _price;
  }

  function s_feeManager() external pure returns (address) {
    return address(0);
  }

  function verify(bytes calldata, bytes calldata) external view returns (bytes memory) {
    uint32 observationTime = block.timestamp > 60 ? uint32(block.timestamp - 60) : uint32(block.timestamp);
    return
      abi.encode(
        keccak256('JPY/USD'),
        observationTime,
        observationTime,
        uint192(0),
        uint192(0),
        uint32(block.timestamp + 3600),
        mockPrice,
        mockPrice,
        mockPrice
      );
  }
}

contract MockConvexBooster {
  function deposit(uint256, uint256, bool) external returns (bool) {
    return true;
  }
}

contract MockConvexBaseRewardPool {
  mapping(address => uint256) public balanceOf;

  function earned(address) external pure returns (uint256) {
    return 0;
  }

  function withdrawAndUnwrap(uint256 amount, bool) external returns (bool) {
    balanceOf[msg.sender] -= amount;
    return true;
  }

  function stake(uint256 amount) external returns (bool) {
    balanceOf[msg.sender] += amount;
    return true;
  }
}

contract MockConvexClaimZap {
  function claimRewards(address[] calldata, uint256[] calldata, bool, bool, bool, uint256, uint256) external {}
}

contract MockCvxRewardPool {
  function earned(address) external pure returns (uint256) {
    return 0;
  }

  function stakeFor(address, uint256) external returns (bool) {
    return true;
  }

  function getReward(address, bool, bool) external returns (bool) {
    return true;
  }

  function withdraw(uint256, bool) external returns (bool) {
    return true;
  }

  function balanceOf(address) external pure returns (uint256) {
    return 0;
  }
}

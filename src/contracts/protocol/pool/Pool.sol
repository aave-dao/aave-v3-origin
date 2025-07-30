// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Multicall, Context} from 'openzeppelin-contracts/contracts/utils/Multicall.sol';
import {VersionedInitializable} from '../../misc/aave-upgradeability/VersionedInitializable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {PoolLogic} from '../libraries/logic/PoolLogic.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {EModeLogic} from '../libraries/logic/EModeLogic.sol';
import {SupplyLogic} from '../libraries/logic/SupplyLogic.sol';
import {FlashLoanLogic} from '../libraries/logic/FlashLoanLogic.sol';
import {BorrowLogic} from '../libraries/logic/BorrowLogic.sol';
import {LiquidationLogic} from '../libraries/logic/LiquidationLogic.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {IERC20WithPermit} from '../../interfaces/IERC20WithPermit.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {PoolStorage} from './PoolStorage.sol';

/**
 * @title Pool contract
 * @author Aave
 * @notice Main point of interaction with an Aave protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Enable/disable their supplied assets as collateral
 *   # Liquidate positions
 *   # Execute Flash Loans
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 */
abstract contract Pool is VersionedInitializable, PoolStorage, IPool, Multicall {
  using ReserveLogic for DataTypes.ReserveData;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  address public immutable RESERVE_INTEREST_RATE_STRATEGY;

  // @notice The name used to fetch the UMBRELLA contract
  bytes32 public constant UMBRELLA = 'UMBRELLA';

  /**
   * @dev Only pool configurator can call functions marked by this modifier.
   */
  modifier onlyPoolConfigurator() {
    _onlyPoolConfigurator();
    _;
  }

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin() {
    _onlyPoolAdmin();
    _;
  }

  /**
   * @dev Only an approved position manager can call functions marked by this modifier.
   */
  modifier onlyPositionManager(address onBehalfOf) {
    _onlyPositionManager(onBehalfOf);
    _;
  }

  /**
   * @dev Only the umbrella contract can call functions marked by this modifier.
   */
  modifier onlyUmbrella() {
    require(ADDRESSES_PROVIDER.getAddress(UMBRELLA) == _msgSender(), Errors.CallerNotUmbrella());
    _;
  }

  function _onlyPoolConfigurator() internal view virtual {
    require(
      ADDRESSES_PROVIDER.getPoolConfigurator() == _msgSender(),
      Errors.CallerNotPoolConfigurator()
    );
  }

  function _onlyPoolAdmin() internal view virtual {
    require(
      IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(_msgSender()),
      Errors.CallerNotPoolAdmin()
    );
  }

  function _onlyPositionManager(address onBehalfOf) internal view virtual {
    require(_positionManager[onBehalfOf][_msgSender()], Errors.CallerNotPositionManager());
  }

  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider, IReserveInterestRateStrategy interestRateStrategy) {
    ADDRESSES_PROVIDER = provider;
    require(address(interestRateStrategy) != address(0), Errors.ZeroAddressNotValid());
    RESERVE_INTEREST_RATE_STRATEGY = address(interestRateStrategy);
  }

  /**
   * @notice Initializes the Pool.
   * @dev Function is invoked by the proxy contract when the Pool contract is added to the
   * PoolAddressesProvider of the market.
   * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
   * @param provider The address of the PoolAddressesProvider
   */
  function initialize(IPoolAddressesProvider provider) external virtual;

  /// @inheritdoc IPool
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) public virtual override {
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        user: _msgSender(),
        asset: asset,
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) public virtual override {
    try
      IERC20WithPermit(asset).permit(
        _msgSender(),
        address(this),
        amount,
        deadline,
        permitV,
        permitR,
        permitS
      )
    {} catch {}
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        user: _msgSender(),
        asset: asset,
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public virtual override returns (uint256) {
    return
      SupplyLogic.executeWithdraw(
        _reserves,
        _reservesList,
        _eModeCategories,
        _usersConfig[_msgSender()],
        DataTypes.ExecuteWithdrawParams({
          user: _msgSender(),
          asset: asset,
          interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
          amount: amount,
          to: to,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[_msgSender()]
        })
      );
  }

  /// @inheritdoc IPool
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) public virtual override {
    BorrowLogic.executeBorrow(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteBorrowParams({
        asset: asset,
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
        user: _msgSender(),
        onBehalfOf: onBehalfOf,
        amount: amount,
        interestRateMode: DataTypes.InterestRateMode(interestRateMode),
        referralCode: referralCode,
        releaseUnderlying: true,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        userEModeCategory: _usersEModeCategory[onBehalfOf],
        priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
      })
    );
  }

  /// @inheritdoc IPool
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) public virtual override returns (uint256) {
    return
      BorrowLogic.executeRepay(
        _reserves,
        _reservesList,
        _eModeCategories,
        _usersConfig[onBehalfOf],
        DataTypes.ExecuteRepayParams({
          asset: asset,
          user: _msgSender(),
          interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
          amount: amount,
          interestRateMode: DataTypes.InterestRateMode(interestRateMode),
          onBehalfOf: onBehalfOf,
          useATokens: false,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[onBehalfOf]
        })
      );
  }

  /// @inheritdoc IPool
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) public virtual override returns (uint256) {
    try
      IERC20WithPermit(asset).permit(
        _msgSender(),
        address(this),
        amount,
        deadline,
        permitV,
        permitR,
        permitS
      )
    {} catch {}

    {
      DataTypes.ExecuteRepayParams memory params = DataTypes.ExecuteRepayParams({
        asset: asset,
        user: _msgSender(),
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
        amount: amount,
        interestRateMode: DataTypes.InterestRateMode(interestRateMode),
        onBehalfOf: onBehalfOf,
        useATokens: false,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        userEModeCategory: _usersEModeCategory[onBehalfOf]
      });
      return
        BorrowLogic.executeRepay(
          _reserves,
          _reservesList,
          _eModeCategories,
          _usersConfig[onBehalfOf],
          params
        );
    }
  }

  /// @inheritdoc IPool
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) public virtual override returns (uint256) {
    return
      BorrowLogic.executeRepay(
        _reserves,
        _reservesList,
        _eModeCategories,
        _usersConfig[_msgSender()],
        DataTypes.ExecuteRepayParams({
          asset: asset,
          user: _msgSender(),
          interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
          amount: amount,
          interestRateMode: DataTypes.InterestRateMode(interestRateMode),
          onBehalfOf: _msgSender(),
          useATokens: true,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[_msgSender()]
        })
      );
  }

  /// @inheritdoc IPool
  function setUserUseReserveAsCollateral(
    address asset,
    bool useAsCollateral
  ) public virtual override {
    SupplyLogic.executeUseReserveAsCollateral(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[_msgSender()],
      _msgSender(),
      asset,
      useAsCollateral,
      ADDRESSES_PROVIDER.getPriceOracle(),
      _usersEModeCategory[_msgSender()]
    );
  }

  /// @inheritdoc IPool
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address borrower,
    uint256 debtToCover,
    bool receiveAToken
  ) public virtual override {
    LiquidationLogic.executeLiquidationCall(
      _reserves,
      _reservesList,
      _usersConfig,
      _eModeCategories,
      DataTypes.ExecuteLiquidationCallParams({
        liquidator: _msgSender(),
        debtToCover: debtToCover,
        collateralAsset: collateralAsset,
        debtAsset: debtAsset,
        borrower: borrower,
        receiveAToken: receiveAToken,
        priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
        borrowerEModeCategory: _usersEModeCategory[borrower],
        priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel(),
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY
      })
    );
  }

  /// @inheritdoc IPool
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) public virtual override {
    DataTypes.FlashloanParams memory flashParams = DataTypes.FlashloanParams({
      user: _msgSender(),
      receiverAddress: receiverAddress,
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
      onBehalfOf: onBehalfOf,
      params: params,
      referralCode: referralCode,
      flashLoanPremium: _flashLoanPremium,
      addressesProvider: address(ADDRESSES_PROVIDER),
      pool: address(this),
      userEModeCategory: _usersEModeCategory[onBehalfOf],
      isAuthorizedFlashBorrower: IACLManager(ADDRESSES_PROVIDER.getACLManager()).isFlashBorrower(
        _msgSender()
      )
    });

    FlashLoanLogic.executeFlashLoan(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[onBehalfOf],
      flashParams
    );
  }

  /// @inheritdoc IPool
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) public virtual override {
    DataTypes.FlashloanSimpleParams memory flashParams = DataTypes.FlashloanSimpleParams({
      user: _msgSender(),
      receiverAddress: receiverAddress,
      asset: asset,
      interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
      amount: amount,
      params: params,
      referralCode: referralCode,
      flashLoanPremium: _flashLoanPremium
    });
    FlashLoanLogic.executeFlashLoanSimple(_reserves[asset], flashParams);
  }

  /// @inheritdoc IPool
  function mintToTreasury(address[] calldata assets) external virtual override {
    PoolLogic.executeMintToTreasury(_reserves, assets);
  }

  /// @inheritdoc IPool
  function getReserveData(
    address asset
  ) external view virtual override returns (DataTypes.ReserveDataLegacy memory res) {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    res.configuration = reserve.configuration;
    res.liquidityIndex = reserve.liquidityIndex;
    res.currentLiquidityRate = reserve.currentLiquidityRate;
    res.variableBorrowIndex = reserve.variableBorrowIndex;
    res.currentVariableBorrowRate = reserve.currentVariableBorrowRate;
    res.lastUpdateTimestamp = reserve.lastUpdateTimestamp;
    res.id = reserve.id;
    res.aTokenAddress = reserve.aTokenAddress;
    res.variableDebtTokenAddress = reserve.variableDebtTokenAddress;
    res.interestRateStrategyAddress = RESERVE_INTEREST_RATE_STRATEGY;
    res.accruedToTreasury = reserve.accruedToTreasury;
    res.unbacked = 0;
    res.isolationModeTotalDebt = reserve.isolationModeTotalDebt;
    // This is a temporary workaround for integrations that are broken by Aave 3.2
    // While the new pool data provider is backward compatible, some integrations hard-code an old implementation
    // To allow them to not have any infrastructural blocker, a mock must be configured in the Aave Pool Addresses Provider, returning zero on all required view methods, instead of reverting
    res.stableDebtTokenAddress = ADDRESSES_PROVIDER.getAddress(bytes32('MOCK_STABLE_DEBT'));
  }

  /// @inheritdoc IPool
  function getVirtualUnderlyingBalance(
    address asset
  ) external view virtual override returns (uint128) {
    return _reserves[asset].virtualUnderlyingBalance;
  }

  /// @inheritdoc IPool
  function getUserAccountData(
    address user
  )
    external
    view
    virtual
    override
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    return
      PoolLogic.executeGetUserAccountData(
        _reserves,
        _reservesList,
        _eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: _usersConfig[user],
          user: user,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          userEModeCategory: _usersEModeCategory[user]
        })
      );
  }

  /// @inheritdoc IPool
  function getConfiguration(
    address asset
  ) external view virtual override returns (DataTypes.ReserveConfigurationMap memory) {
    return _reserves[asset].configuration;
  }

  /// @inheritdoc IPool
  function getUserConfiguration(
    address user
  ) external view virtual override returns (DataTypes.UserConfigurationMap memory) {
    return _usersConfig[user];
  }

  /// @inheritdoc IPool
  function getReserveNormalizedIncome(
    address asset
  ) external view virtual override returns (uint256) {
    return _reserves[asset].getNormalizedIncome();
  }

  /// @inheritdoc IPool
  function getReserveNormalizedVariableDebt(
    address asset
  ) external view virtual override returns (uint256) {
    return _reserves[asset].getNormalizedDebt();
  }

  /// @inheritdoc IPool
  function getReservesList() external view virtual override returns (address[] memory) {
    uint256 reservesListCount = _reservesCount;
    uint256 droppedReservesCount = 0;
    address[] memory reservesList = new address[](reservesListCount);

    for (uint256 i = 0; i < reservesListCount; i++) {
      if (_reservesList[i] != address(0)) {
        reservesList[i - droppedReservesCount] = _reservesList[i];
      } else {
        droppedReservesCount++;
      }
    }

    // Reduces the length of the reserves array by `droppedReservesCount`
    assembly {
      mstore(reservesList, sub(reservesListCount, droppedReservesCount))
    }
    return reservesList;
  }

  /// @inheritdoc IPool
  function getReservesCount() external view virtual override returns (uint256) {
    return _reservesCount;
  }

  /// @inheritdoc IPool
  function getReserveAddressById(uint16 id) external view returns (address) {
    return _reservesList[id];
  }

  /// @inheritdoc IPool
  function FLASHLOAN_PREMIUM_TOTAL() public view virtual override returns (uint128) {
    return _flashLoanPremium;
  }

  /// @inheritdoc IPool
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() public view virtual override returns (uint128) {
    return 100_00;
  }

  /// @inheritdoc IPool
  function MAX_NUMBER_RESERVES() public view virtual override returns (uint16) {
    return ReserveConfiguration.MAX_RESERVES_COUNT;
  }

  /// @inheritdoc IPool
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 scaledAmount,
    uint256 scaledBalanceFromBefore,
    uint256 scaledBalanceToBefore
  ) external virtual override {
    require(_msgSender() == _reserves[asset].aTokenAddress, Errors.CallerNotAToken());
    SupplyLogic.executeFinalizeTransfer(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig,
      DataTypes.FinalizeTransferParams({
        asset: asset,
        from: from,
        to: to,
        scaledAmount: scaledAmount,
        scaledBalanceFromBefore: scaledBalanceFromBefore,
        scaledBalanceToBefore: scaledBalanceToBefore,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        fromEModeCategory: _usersEModeCategory[from]
      })
    );
  }

  /// @inheritdoc IPool
  function initReserve(
    address asset,
    address aTokenAddress,
    address variableDebtAddress
  ) external virtual override onlyPoolConfigurator {
    if (
      PoolLogic.executeInitReserve(
        _reserves,
        _reservesList,
        DataTypes.InitReserveParams({
          asset: asset,
          aTokenAddress: aTokenAddress,
          variableDebtAddress: variableDebtAddress,
          reservesCount: _reservesCount,
          maxNumberReserves: MAX_NUMBER_RESERVES()
        })
      )
    ) {
      _reservesCount++;
    }
  }

  /// @inheritdoc IPool
  function dropReserve(address asset) external virtual override onlyPoolConfigurator {
    PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
  }

  /// @inheritdoc IPool
  function syncIndexesState(address asset) external virtual override onlyPoolConfigurator {
    PoolLogic.executeSyncIndexesState(_reserves[asset]);
  }

  /// @inheritdoc IPool
  function syncRatesState(address asset) external virtual override onlyPoolConfigurator {
    PoolLogic.executeSyncRatesState(_reserves[asset], asset, RESERVE_INTEREST_RATE_STRATEGY);
  }

  /// @inheritdoc IPool
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external virtual override onlyPoolConfigurator {
    require(asset != address(0), Errors.ZeroAddressNotValid());
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.AssetNotListed());
    _reserves[asset].configuration = configuration;
  }

  /// @inheritdoc IPool
  function updateFlashloanPremium(
    uint128 flashLoanPremium
  ) external virtual override onlyPoolConfigurator {
    _flashLoanPremium = flashLoanPremium;
  }

  /// @inheritdoc IPool
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategoryBaseConfiguration calldata category
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EModeCategoryReserved());
    _eModeCategories[id].ltv = category.ltv;
    _eModeCategories[id].liquidationThreshold = category.liquidationThreshold;
    _eModeCategories[id].liquidationBonus = category.liquidationBonus;
    _eModeCategories[id].label = category.label;
  }

  /// @inheritdoc IPool
  function configureEModeCategoryCollateralBitmap(
    uint8 id,
    uint128 collateralBitmap
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EModeCategoryReserved());
    _eModeCategories[id].collateralBitmap = collateralBitmap;
  }

  /// @inheritdoc IPool
  function configureEModeCategoryBorrowableBitmap(
    uint8 id,
    uint128 borrowableBitmap
  ) external virtual override onlyPoolConfigurator {
    // category 0 is reserved for volatile heterogeneous assets and it's always disabled
    require(id != 0, Errors.EModeCategoryReserved());
    _eModeCategories[id].borrowableBitmap = borrowableBitmap;
  }

  /// @inheritdoc IPool
  function getEModeCategoryData(
    uint8 id
  ) external view virtual override returns (DataTypes.EModeCategoryLegacy memory) {
    DataTypes.EModeCategory storage category = _eModeCategories[id];
    return
      DataTypes.EModeCategoryLegacy({
        ltv: category.ltv,
        liquidationThreshold: category.liquidationThreshold,
        liquidationBonus: category.liquidationBonus,
        priceSource: address(0),
        label: category.label
      });
  }

  /// @inheritdoc IPool
  function getEModeCategoryCollateralConfig(
    uint8 id
  ) external view returns (DataTypes.CollateralConfig memory res) {
    res.ltv = _eModeCategories[id].ltv;
    res.liquidationThreshold = _eModeCategories[id].liquidationThreshold;
    res.liquidationBonus = _eModeCategories[id].liquidationBonus;
  }

  /// @inheritdoc IPool
  function getEModeCategoryLabel(uint8 id) external view returns (string memory) {
    return _eModeCategories[id].label;
  }

  /// @inheritdoc IPool
  function getEModeCategoryCollateralBitmap(uint8 id) external view returns (uint128) {
    return _eModeCategories[id].collateralBitmap;
  }

  /// @inheritdoc IPool
  function getEModeCategoryBorrowableBitmap(uint8 id) external view returns (uint128) {
    return _eModeCategories[id].borrowableBitmap;
  }

  /// @inheritdoc IPool
  function setUserEMode(uint8 categoryId) external virtual override {
    EModeLogic.executeSetUserEMode(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersEModeCategory,
      _usersConfig[_msgSender()],
      _msgSender(),
      ADDRESSES_PROVIDER.getPriceOracle(),
      categoryId
    );
  }

  /// @inheritdoc IPool
  function getUserEMode(address user) external view virtual override returns (uint256) {
    return _usersEModeCategory[user];
  }

  /// @inheritdoc IPool
  function resetIsolationModeTotalDebt(
    address asset
  ) external virtual override onlyPoolConfigurator {
    PoolLogic.executeResetIsolationModeTotalDebt(_reserves, asset);
  }

  /// @inheritdoc IPool
  function getLiquidationGracePeriod(
    address asset
  ) external view virtual override returns (uint40) {
    return _reserves[asset].liquidationGracePeriodUntil;
  }

  /// @inheritdoc IPool
  function setLiquidationGracePeriod(
    address asset,
    uint40 until
  ) external virtual override onlyPoolConfigurator {
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.AssetNotListed());
    PoolLogic.executeSetLiquidationGracePeriod(_reserves, asset, until);
  }

  /// @inheritdoc IPool
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external virtual override onlyPoolAdmin {
    PoolLogic.executeRescueTokens(token, to, amount);
  }

  /// @inheritdoc IPool
  /// @dev Deprecated: maintained for compatibility purposes
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external virtual override {
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      _usersConfig[onBehalfOf],
      DataTypes.ExecuteSupplyParams({
        user: _msgSender(),
        asset: asset,
        interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /// @inheritdoc IPool
  function eliminateReserveDeficit(
    address asset,
    uint256 amount
  ) external override onlyUmbrella returns (uint256) {
    return
      LiquidationLogic.executeEliminateDeficit(
        _reserves,
        _usersConfig[_msgSender()],
        DataTypes.ExecuteEliminateDeficitParams({
          user: _msgSender(),
          asset: asset,
          amount: amount,
          interestRateStrategyAddress: RESERVE_INTEREST_RATE_STRATEGY
        })
      );
  }

  /// @inheritdoc IPool
  function approvePositionManager(address positionManager, bool approve) external override {
    if (_positionManager[_msgSender()][positionManager] == approve) return;
    _positionManager[_msgSender()][positionManager] = approve;

    if (approve) {
      emit PositionManagerApproved({user: _msgSender(), positionManager: positionManager});
    } else {
      emit PositionManagerRevoked({user: _msgSender(), positionManager: positionManager});
    }
  }

  /// @inheritdoc IPool
  function renouncePositionManagerRole(address user) external override {
    if (_positionManager[user][_msgSender()] == false) return;
    _positionManager[user][_msgSender()] = false;
    emit PositionManagerRevoked({user: user, positionManager: _msgSender()});
  }

  /// @inheritdoc IPool
  function setUserUseReserveAsCollateralOnBehalfOf(
    address asset,
    bool useAsCollateral,
    address onBehalfOf
  ) external override onlyPositionManager(onBehalfOf) {
    SupplyLogic.executeUseReserveAsCollateral(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersConfig[onBehalfOf],
      onBehalfOf,
      asset,
      useAsCollateral,
      ADDRESSES_PROVIDER.getPriceOracle(),
      _usersEModeCategory[onBehalfOf]
    );
  }

  /// @inheritdoc IPool
  function setUserEModeOnBehalfOf(
    uint8 categoryId,
    address onBehalfOf
  ) external override onlyPositionManager(onBehalfOf) {
    EModeLogic.executeSetUserEMode(
      _reserves,
      _reservesList,
      _eModeCategories,
      _usersEModeCategory,
      _usersConfig[onBehalfOf],
      onBehalfOf,
      ADDRESSES_PROVIDER.getPriceOracle(),
      categoryId
    );
  }

  /// @inheritdoc IPool
  function isApprovedPositionManager(
    address user,
    address positionManager
  ) external view override returns (bool) {
    return _positionManager[user][positionManager];
  }

  /// @inheritdoc IPool
  function getReserveDeficit(address asset) external view virtual returns (uint256) {
    return _reserves[asset].deficit;
  }

  /// @inheritdoc IPool
  function getReserveAToken(address asset) external view virtual returns (address) {
    return _reserves[asset].aTokenAddress;
  }

  /// @inheritdoc IPool
  function getReserveVariableDebtToken(address asset) external view virtual returns (address) {
    return _reserves[asset].variableDebtTokenAddress;
  }

  /// @inheritdoc IPool
  function getFlashLoanLogic() external pure returns (address) {
    return address(FlashLoanLogic);
  }

  /// @inheritdoc IPool
  function getBorrowLogic() external pure returns (address) {
    return address(BorrowLogic);
  }

  /// @inheritdoc IPool
  function getEModeLogic() external pure returns (address) {
    return address(EModeLogic);
  }

  /// @inheritdoc IPool
  function getLiquidationLogic() external pure returns (address) {
    return address(LiquidationLogic);
  }

  /// @inheritdoc IPool
  function getPoolLogic() external pure returns (address) {
    return address(PoolLogic);
  }

  /// @inheritdoc IPool
  function getSupplyLogic() external pure returns (address) {
    return address(SupplyLogic);
  }
}

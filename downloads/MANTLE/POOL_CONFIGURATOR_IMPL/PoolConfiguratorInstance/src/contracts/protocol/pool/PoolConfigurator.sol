// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VersionedInitializable} from '../../misc/aave-upgradeability/VersionedInitializable.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {EModeConfiguration} from '../libraries/configuration/EModeConfiguration.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IDefaultInterestRateStrategyV2} from '../../interfaces/IDefaultInterestRateStrategyV2.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {ConfiguratorLogic} from '../libraries/logic/ConfiguratorLogic.sol';
import {ConfiguratorInputTypes} from '../libraries/types/ConfiguratorInputTypes.sol';
import {IPoolConfigurator} from '../../interfaces/IPoolConfigurator.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {IPoolDataProvider} from '../../interfaces/IPoolDataProvider.sol';

/**
 * @title PoolConfigurator
 * @author Aave
 * @dev Implements the configuration methods for the Aave protocol
 */
abstract contract PoolConfigurator is VersionedInitializable, IPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPoolAddressesProvider internal _addressesProvider;
  IPool internal _pool;

  mapping(address => uint256) internal _pendingLtv;

  uint40 public constant MAX_GRACE_PERIOD = 4 hours;

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin() {
    _onlyPoolAdmin();
    _;
  }

  /**
   * @dev Only emergency or pool admin can call functions marked by this modifier.
   */
  modifier onlyEmergencyOrPoolAdmin() {
    _onlyPoolOrEmergencyAdmin();
    _;
  }

  /**
   * @dev Only asset listing or pool admin can call functions marked by this modifier.
   */
  modifier onlyAssetListingOrPoolAdmins() {
    _onlyAssetListingOrPoolAdmins();
    _;
  }

  /**
   * @dev Only risk or pool admin can call functions marked by this modifier.
   */
  modifier onlyRiskOrPoolAdmins() {
    _onlyRiskOrPoolAdmins();
    _;
  }

  /**
   * @dev Only risk, pool or emergency admin can call functions marked by this modifier.
   */
  modifier onlyRiskOrPoolOrEmergencyAdmins() {
    _onlyRiskOrPoolOrEmergencyAdmins();
    _;
  }

  function initialize(IPoolAddressesProvider provider) public virtual;

  /// @inheritdoc IPoolConfigurator
  function initReserves(
    ConfiguratorInputTypes.InitReserveInput[] calldata input
  ) external override onlyAssetListingOrPoolAdmins {
    IPool cachedPool = _pool;

    for (uint256 i = 0; i < input.length; i++) {
      ConfiguratorLogic.executeInitReserve(cachedPool, input[i]);
      emit ReserveInterestRateDataChanged(
        input[i].underlyingAsset,
        input[i].interestRateStrategyAddress,
        input[i].interestRateData
      );
    }
  }

  /// @inheritdoc IPoolConfigurator
  function dropReserve(address asset) external override onlyPoolAdmin {
    _pool.dropReserve(asset);
    emit ReserveDropped(asset);
  }

  /// @inheritdoc IPoolConfigurator
  function updateAToken(
    ConfiguratorInputTypes.UpdateATokenInput calldata input
  ) external override onlyPoolAdmin {
    ConfiguratorLogic.executeUpdateAToken(_pool, input);
  }

  /// @inheritdoc IPoolConfigurator
  function updateVariableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external override onlyPoolAdmin {
    ConfiguratorLogic.executeUpdateVariableDebtToken(_pool, input);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveBorrowing(address asset, bool enabled) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setBorrowingEnabled(enabled);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveBorrowing(asset, enabled);
  }

  /// @inheritdoc IPoolConfigurator
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external override onlyRiskOrPoolAdmins {
    //validation of the parameters: the LTV can
    //only be lower or equal than the liquidation threshold
    //(otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.INVALID_RESERVE_PARAMS);

    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    if (liquidationThreshold != 0) {
      //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      //collateral than needed to cover the debt
      require(liquidationBonus > PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_RESERVE_PARAMS);

      //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      //a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
        Errors.INVALID_RESERVE_PARAMS
      );
    } else {
      require(liquidationBonus == 0, Errors.INVALID_RESERVE_PARAMS);
      //if the liquidation threshold is being set to 0,
      // the reserve is being disabled as collateral. To do so,
      //we need to ensure no liquidity is supplied
      _checkNoSuppliers(asset);
    }

    uint256 newLtv = ltv;

    if (currentConfig.getFrozen()) {
      _pendingLtv[asset] = ltv;
      newLtv = 0;

      emit PendingLtvChanged(asset, ltv);
    } else {
      currentConfig.setLtv(ltv);
    }

    currentConfig.setLiquidationThreshold(liquidationThreshold);
    currentConfig.setLiquidationBonus(liquidationBonus);

    _pool.setConfiguration(asset, currentConfig);

    emit CollateralConfigurationChanged(asset, newLtv, liquidationThreshold, liquidationBonus);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveFlashLoaning(
    address asset,
    bool enabled
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    currentConfig.setFlashLoanEnabled(enabled);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveFlashLoaning(asset, enabled);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveActive(address asset, bool active) external override onlyPoolAdmin {
    if (!active) _checkNoSuppliers(asset);
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setActive(active);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveActive(asset, active);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveFreeze(
    address asset,
    bool freeze
  ) external override onlyRiskOrPoolOrEmergencyAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    require(freeze != currentConfig.getFrozen(), Errors.INVALID_FREEZE_STATE);

    currentConfig.setFrozen(freeze);

    uint256 ltvSet;
    uint256 pendingLtvSet;

    if (freeze) {
      pendingLtvSet = currentConfig.getLtv();
      _pendingLtv[asset] = pendingLtvSet;
      currentConfig.setLtv(0);
    } else {
      ltvSet = _pendingLtv[asset];
      currentConfig.setLtv(ltvSet);
      delete _pendingLtv[asset];
    }

    emit PendingLtvChanged(asset, pendingLtvSet);
    emit CollateralConfigurationChanged(
      asset,
      ltvSet,
      currentConfig.getLiquidationThreshold(),
      currentConfig.getLiquidationBonus()
    );

    _pool.setConfiguration(asset, currentConfig);
    emit ReserveFrozen(asset, freeze);
  }

  /// @inheritdoc IPoolConfigurator
  function setBorrowableInIsolation(
    address asset,
    bool borrowable
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setBorrowableInIsolation(borrowable);
    _pool.setConfiguration(asset, currentConfig);
    emit BorrowableInIsolationChanged(asset, borrowable);
  }

  /// @inheritdoc IPoolConfigurator
  function setReservePause(
    address asset,
    bool paused,
    uint40 gracePeriod
  ) public override onlyEmergencyOrPoolAdmin {
    if (!paused && gracePeriod != 0) {
      require(gracePeriod <= MAX_GRACE_PERIOD, Errors.INVALID_GRACE_PERIOD);

      uint40 until = uint40(block.timestamp) + gracePeriod;
      _pool.setLiquidationGracePeriod(asset, until);
      emit LiquidationGracePeriodChanged(asset, until);
    }

    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setPaused(paused);
    _pool.setConfiguration(asset, currentConfig);
    emit ReservePaused(asset, paused);
  }

  /// @inheritdoc IPoolConfigurator
  function setReservePause(address asset, bool paused) external override onlyEmergencyOrPoolAdmin {
    setReservePause(asset, paused, 0);
  }

  /// @inheritdoc IPoolConfigurator
  function disableLiquidationGracePeriod(address asset) external override onlyEmergencyOrPoolAdmin {
    // set the liquidation grace period in the past to disable liquidation grace period
    _pool.setLiquidationGracePeriod(asset, 0);

    emit LiquidationGracePeriodDisabled(asset);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveFactor(
    address asset,
    uint256 newReserveFactor
  ) external override onlyRiskOrPoolAdmins {
    require(newReserveFactor <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    _pool.syncIndexesState(asset);

    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldReserveFactor = currentConfig.getReserveFactor();
    currentConfig.setReserveFactor(newReserveFactor);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveFactorChanged(asset, oldReserveFactor, newReserveFactor);

    _pool.syncRatesState(asset);
  }

  /// @inheritdoc IPoolConfigurator
  function setDebtCeiling(
    address asset,
    uint256 newDebtCeiling
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    uint256 oldDebtCeiling = currentConfig.getDebtCeiling();
    if (currentConfig.getLiquidationThreshold() != 0 && oldDebtCeiling == 0) {
      _checkNoSuppliers(asset);
    }
    currentConfig.setDebtCeiling(newDebtCeiling);
    _pool.setConfiguration(asset, currentConfig);

    if (newDebtCeiling == 0) {
      _pool.resetIsolationModeTotalDebt(asset);
    }

    emit DebtCeilingChanged(asset, oldDebtCeiling, newDebtCeiling);
  }

  /// @inheritdoc IPoolConfigurator
  function setSiloedBorrowing(
    address asset,
    bool newSiloed
  ) external override onlyRiskOrPoolAdmins {
    if (newSiloed) {
      _checkNoBorrowers(asset);
    }
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    bool oldSiloed = currentConfig.getSiloedBorrowing();

    currentConfig.setSiloedBorrowing(newSiloed);

    _pool.setConfiguration(asset, currentConfig);

    emit SiloedBorrowingChanged(asset, oldSiloed, newSiloed);
  }

  /// @inheritdoc IPoolConfigurator
  function setBorrowCap(
    address asset,
    uint256 newBorrowCap
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldBorrowCap = currentConfig.getBorrowCap();
    currentConfig.setBorrowCap(newBorrowCap);
    _pool.setConfiguration(asset, currentConfig);
    emit BorrowCapChanged(asset, oldBorrowCap, newBorrowCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setSupplyCap(
    address asset,
    uint256 newSupplyCap
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldSupplyCap = currentConfig.getSupplyCap();
    currentConfig.setSupplyCap(newSupplyCap);
    _pool.setConfiguration(asset, currentConfig);
    emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setLiquidationProtocolFee(
    address asset,
    uint256 newFee
  ) external override onlyRiskOrPoolAdmins {
    require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_LIQUIDATION_PROTOCOL_FEE);
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldFee = currentConfig.getLiquidationProtocolFee();
    currentConfig.setLiquidationProtocolFee(newFee);
    _pool.setConfiguration(asset, currentConfig);
    emit LiquidationProtocolFeeChanged(asset, oldFee, newFee);
  }

  /// @inheritdoc IPoolConfigurator
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    string calldata label
  ) external override onlyRiskOrPoolAdmins {
    require(ltv != 0, Errors.INVALID_EMODE_CATEGORY_PARAMS);
    require(liquidationThreshold != 0, Errors.INVALID_EMODE_CATEGORY_PARAMS);

    // validation of the parameters: the LTV can
    // only be lower or equal than the liquidation threshold
    // (otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.INVALID_EMODE_CATEGORY_PARAMS);
    require(
      liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
      Errors.INVALID_EMODE_CATEGORY_PARAMS
    );

    // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
    // a loan is taken there is enough collateral available to cover the liquidation bonus
    require(
      uint256(liquidationThreshold).percentMul(liquidationBonus) <=
        PercentageMath.PERCENTAGE_FACTOR,
      Errors.INVALID_EMODE_CATEGORY_PARAMS
    );

    DataTypes.EModeCategoryBaseConfiguration memory categoryData;
    categoryData.ltv = ltv;
    categoryData.liquidationThreshold = liquidationThreshold;
    categoryData.liquidationBonus = liquidationBonus;
    categoryData.label = label;

    _pool.configureEModeCategory(categoryId, categoryData);
    emit EModeCategoryAdded(
      categoryId,
      ltv,
      liquidationThreshold,
      liquidationBonus,
      address(0),
      label
    );
  }

  /// @inheritdoc IPoolConfigurator
  function setAssetCollateralInEMode(
    address asset,
    uint8 categoryId,
    bool allowed
  ) external override onlyRiskOrPoolAdmins {
    uint128 collateralBitmap = _pool.getEModeCategoryCollateralBitmap(categoryId);
    DataTypes.ReserveDataLegacy memory reserveData = _pool.getReserveData(asset);
    require(reserveData.id != 0 || _pool.getReservesList()[0] == asset, Errors.ASSET_NOT_LISTED);
    collateralBitmap = EModeConfiguration.setReserveBitmapBit(
      collateralBitmap,
      reserveData.id,
      allowed
    );
    _pool.configureEModeCategoryCollateralBitmap(categoryId, collateralBitmap);
    emit AssetCollateralInEModeChanged(asset, categoryId, allowed);
  }

  /// @inheritdoc IPoolConfigurator
  function setAssetBorrowableInEMode(
    address asset,
    uint8 categoryId,
    bool borrowable
  ) external override onlyRiskOrPoolAdmins {
    uint128 borrowableBitmap = _pool.getEModeCategoryBorrowableBitmap(categoryId);
    DataTypes.ReserveDataLegacy memory reserveData = _pool.getReserveData(asset);
    require(reserveData.id != 0 || _pool.getReservesList()[0] == asset, Errors.ASSET_NOT_LISTED);
    borrowableBitmap = EModeConfiguration.setReserveBitmapBit(
      borrowableBitmap,
      reserveData.id,
      borrowable
    );
    _pool.configureEModeCategoryBorrowableBitmap(categoryId, borrowableBitmap);
    emit AssetBorrowableInEModeChanged(asset, categoryId, borrowable);
  }

  /// @inheritdoc IPoolConfigurator
  function setUnbackedMintCap(
    address asset,
    uint256 newUnbackedMintCap
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldUnbackedMintCap = currentConfig.getUnbackedMintCap();
    currentConfig.setUnbackedMintCap(newUnbackedMintCap);
    _pool.setConfiguration(asset, currentConfig);
    emit UnbackedMintCapChanged(asset, oldUnbackedMintCap, newUnbackedMintCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveInterestRateData(
    address asset,
    bytes calldata rateData
  ) external onlyRiskOrPoolAdmins {
    DataTypes.ReserveDataLegacy memory reserve = _pool.getReserveData(asset);
    _updateInterestRateStrategy(asset, reserve, reserve.interestRateStrategyAddress, rateData);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress,
    bytes calldata rateData
  ) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveDataLegacy memory reserve = _pool.getReserveData(asset);
    _updateInterestRateStrategy(asset, reserve, rateStrategyAddress, rateData);
  }

  /// @inheritdoc IPoolConfigurator
  function setPoolPause(bool paused, uint40 gracePeriod) public override onlyEmergencyOrPoolAdmin {
    address[] memory reserves = _pool.getReservesList();

    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] != address(0)) {
        setReservePause(reserves[i], paused, gracePeriod);
      }
    }
  }

  /// @inheritdoc IPoolConfigurator
  function setPoolPause(bool paused) external override onlyEmergencyOrPoolAdmin {
    setPoolPause(paused, 0);
  }

  /// @inheritdoc IPoolConfigurator
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external override onlyPoolAdmin {
    require(
      newBridgeProtocolFee <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.BRIDGE_PROTOCOL_FEE_INVALID
    );
    uint256 oldBridgeProtocolFee = _pool.BRIDGE_PROTOCOL_FEE();
    _pool.updateBridgeProtocolFee(newBridgeProtocolFee);
    emit BridgeProtocolFeeUpdated(oldBridgeProtocolFee, newBridgeProtocolFee);
  }

  /// @inheritdoc IPoolConfigurator
  function updateFlashloanPremiumTotal(
    uint128 newFlashloanPremiumTotal
  ) external override onlyPoolAdmin {
    require(
      newFlashloanPremiumTotal <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.FLASHLOAN_PREMIUM_INVALID
    );
    uint128 oldFlashloanPremiumTotal = _pool.FLASHLOAN_PREMIUM_TOTAL();
    _pool.updateFlashloanPremiums(newFlashloanPremiumTotal, _pool.FLASHLOAN_PREMIUM_TO_PROTOCOL());
    emit FlashloanPremiumTotalUpdated(oldFlashloanPremiumTotal, newFlashloanPremiumTotal);
  }

  /// @inheritdoc IPoolConfigurator
  function updateFlashloanPremiumToProtocol(
    uint128 newFlashloanPremiumToProtocol
  ) external override onlyPoolAdmin {
    require(
      newFlashloanPremiumToProtocol <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.FLASHLOAN_PREMIUM_INVALID
    );
    uint128 oldFlashloanPremiumToProtocol = _pool.FLASHLOAN_PREMIUM_TO_PROTOCOL();
    _pool.updateFlashloanPremiums(_pool.FLASHLOAN_PREMIUM_TOTAL(), newFlashloanPremiumToProtocol);
    emit FlashloanPremiumToProtocolUpdated(
      oldFlashloanPremiumToProtocol,
      newFlashloanPremiumToProtocol
    );
  }

  /// @inheritdoc IPoolConfigurator
  function getPendingLtv(address asset) external view override returns (uint256) {
    return _pendingLtv[asset];
  }

  /// @inheritdoc IPoolConfigurator
  function getConfiguratorLogic() external pure returns (address) {
    return address(ConfiguratorLogic);
  }

  function _updateInterestRateStrategy(
    address asset,
    DataTypes.ReserveDataLegacy memory reserve,
    address newRateStrategyAddress,
    bytes calldata rateData
  ) internal {
    address oldRateStrategyAddress = reserve.interestRateStrategyAddress;

    _pool.syncIndexesState(asset);

    IDefaultInterestRateStrategyV2(newRateStrategyAddress).setInterestRateParams(asset, rateData);
    emit ReserveInterestRateDataChanged(asset, newRateStrategyAddress, rateData);

    if (oldRateStrategyAddress != newRateStrategyAddress) {
      _pool.setReserveInterestRateStrategyAddress(asset, newRateStrategyAddress);
      emit ReserveInterestRateStrategyChanged(
        asset,
        oldRateStrategyAddress,
        newRateStrategyAddress
      );
    }

    _pool.syncRatesState(asset);
  }

  function _checkNoSuppliers(address asset) internal view {
    DataTypes.ReserveDataLegacy memory reserveData = _pool.getReserveData(asset);
    uint256 totalSupplied = IPoolDataProvider(_addressesProvider.getPoolDataProvider())
      .getATokenTotalSupply(asset);

    require(
      totalSupplied == 0 && reserveData.accruedToTreasury == 0,
      Errors.RESERVE_LIQUIDITY_NOT_ZERO
    );
  }

  function _checkNoBorrowers(address asset) internal view {
    uint256 totalDebt = IPoolDataProvider(_addressesProvider.getPoolDataProvider()).getTotalDebt(
      asset
    );
    require(totalDebt == 0, Errors.RESERVE_DEBT_NOT_ZERO);
  }

  function _onlyPoolAdmin() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
  }

  function _onlyPoolOrEmergencyAdmin() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isPoolAdmin(msg.sender) || aclManager.isEmergencyAdmin(msg.sender),
      Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN
    );
  }

  function _onlyAssetListingOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    );
  }

  function _onlyRiskOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
    );
  }

  function _onlyRiskOrPoolOrEmergencyAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) ||
        aclManager.isPoolAdmin(msg.sender) ||
        aclManager.isEmergencyAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN
    );
  }
}

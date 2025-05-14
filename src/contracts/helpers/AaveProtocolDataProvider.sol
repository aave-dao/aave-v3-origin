// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IVariableDebtToken} from '../interfaces/IVariableDebtToken.sol';
import {IPool} from '../interfaces/IPool.sol';
import {IPoolDataProvider} from '../interfaces/IPoolDataProvider.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

/**
 * @title AaveProtocolDataProvider
 * @author Aave
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract AaveProtocolDataProvider is IPoolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using WadRayMath for uint256;

  address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @inheritdoc IPoolDataProvider
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  /// @inheritdoc IPoolDataProvider
  IPool public immutable POOL;

  /**
   * @notice Constructor
   * @param addressesProvider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider addressesProvider) {
    ADDRESSES_PROVIDER = addressesProvider;

    address pool = addressesProvider.getPool();
    require(pool != address(0), Errors.ZeroAddressNotValid());

    // @dev The pool can be immutable, because in practice it never changes after initialization.
    // The reason why it is not an actual `immutable` on `ADDRESSES_PROVIDER` is that there is a cross reference between ADDRESSES_PROVIDER <> Pool,
    // which in turn makes is complicated to have it `immutable` on both contracts.
    POOL = IPool(pool);
  }

  /// @inheritdoc IPoolDataProvider
  function getAllReservesTokens() external view override returns (TokenData[] memory) {
    address[] memory reserves = POOL.getReservesList();
    TokenData[] memory reservesTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] == MKR) {
        reservesTokens[i] = TokenData({symbol: 'MKR', tokenAddress: reserves[i]});
        continue;
      }
      if (reserves[i] == ETH) {
        reservesTokens[i] = TokenData({symbol: 'ETH', tokenAddress: reserves[i]});
        continue;
      }
      reservesTokens[i] = TokenData({
        symbol: IERC20Detailed(reserves[i]).symbol(),
        tokenAddress: reserves[i]
      });
    }
    return reservesTokens;
  }

  /// @inheritdoc IPoolDataProvider
  function getAllATokens() external view override returns (TokenData[] memory) {
    address[] memory reserves = POOL.getReservesList();
    TokenData[] memory aTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      address aTokenAddress = POOL.getReserveAToken(reserves[i]);
      aTokens[i] = TokenData({
        symbol: IERC20Detailed(aTokenAddress).symbol(),
        tokenAddress: aTokenAddress
      });
    }
    return aTokens;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    override
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = POOL.getConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration
      .getParams();

    (isActive, isFrozen, borrowingEnabled, ) = configuration.getFlags();

    // @notice all stable debt related parameters deprecated in v3.2.0
    stableBorrowRateEnabled = false;

    usageAsCollateralEnabled = liquidationThreshold != 0;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveCaps(
    address asset
  ) external view override returns (uint256 borrowCap, uint256 supplyCap) {
    (borrowCap, supplyCap) = POOL.getConfiguration(asset).getCaps();
  }

  /// @inheritdoc IPoolDataProvider
  function getPaused(address asset) external view override returns (bool isPaused) {
    (, , , isPaused) = POOL.getConfiguration(asset).getFlags();
  }

  /// @inheritdoc IPoolDataProvider
  function getSiloedBorrowing(address asset) external view override returns (bool) {
    return POOL.getConfiguration(asset).getSiloedBorrowing();
  }

  /// @inheritdoc IPoolDataProvider
  function getLiquidationProtocolFee(address asset) external view override returns (uint256) {
    return POOL.getConfiguration(asset).getLiquidationProtocolFee();
  }

  /// @inheritdoc IPoolDataProvider
  function getUnbackedMintCap(address) external pure override returns (uint256) {
    return 0;
  }

  /// @inheritdoc IPoolDataProvider
  function getDebtCeiling(address asset) external view override returns (uint256) {
    return POOL.getConfiguration(asset).getDebtCeiling();
  }

  /// @inheritdoc IPoolDataProvider
  function getDebtCeilingDecimals() external pure override returns (uint256) {
    return ReserveConfiguration.DEBT_CEILING_DECIMALS;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveData(
    address asset
  )
    external
    view
    override
    returns (
      uint256 /* unbacked */,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256,
      uint256,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveDataLegacy memory reserve = POOL.getReserveData(asset);

    // @notice all stable debt related parameters deprecated in v3.2.0
    return (
      0, // @dev unbacked is deprecated from v3.4.0, always zero, never used
      reserve.accruedToTreasury,
      IERC20Detailed(reserve.aTokenAddress).totalSupply(),
      0,
      IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      0,
      0,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  /// @inheritdoc IPoolDataProvider
  function getATokenTotalSupply(address asset) external view override returns (uint256) {
    address aTokenAddress = POOL.getReserveAToken(asset);
    return IERC20Detailed(aTokenAddress).totalSupply();
  }

  /// @inheritdoc IPoolDataProvider
  function getTotalDebt(address asset) external view override returns (uint256) {
    address variableDebtTokenAddress = POOL.getReserveVariableDebtToken(asset);
    return IERC20Detailed(variableDebtTokenAddress).totalSupply();
  }

  /// @inheritdoc IPoolDataProvider
  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    override
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.ReserveDataLegacy memory reserve = POOL.getReserveData(asset);

    DataTypes.UserConfigurationMap memory userConfig = POOL.getUserConfiguration(user);

    currentATokenBalance = IERC20Detailed(reserve.aTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress).balanceOf(user);

    // @notice all stable debt related parameters deprecated in v3.2.0
    currentStableDebt = principalStableDebt = stableBorrowRate = stableRateLastUpdated = 0;

    scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    override
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    // @notice all stable debt related parameters deprecated in v3.2.0
    return (POOL.getReserveAToken(asset), address(0), POOL.getReserveVariableDebtToken(asset));
  }

  /// @inheritdoc IPoolDataProvider
  function getInterestRateStrategyAddress(
    address
  ) external view override returns (address irStrategyAddress) {
    return POOL.RESERVE_INTEREST_RATE_STRATEGY();
  }

  /// @inheritdoc IPoolDataProvider
  function getFlashLoanEnabled(address asset) external view override returns (bool) {
    DataTypes.ReserveConfigurationMap memory configuration = POOL.getConfiguration(asset);

    return configuration.getFlashLoanEnabled();
  }

  /// @inheritdoc IPoolDataProvider
  function getIsVirtualAccActive(address) external pure override returns (bool) {
    return true;
  }

  /// @inheritdoc IPoolDataProvider
  function getVirtualUnderlyingBalance(address asset) external view override returns (uint256) {
    return POOL.getVirtualUnderlyingBalance(asset);
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveDeficit(address asset) external view override returns (uint256) {
    return POOL.getReserveDeficit(asset);
  }
}

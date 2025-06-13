// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {IDefaultInterestRateStrategyV2} from '../interfaces/IDefaultInterestRateStrategyV2.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';

/**
 * @title DefaultReserveInterestRateStrategyV2 contract
 * @author BGD Labs
 * @notice Default interest rate strategy used by the Aave protocol
 * @dev Strategies are pool-specific: each contract CAN'T be used across different Aave pools
 *   due to the caching of the PoolAddressesProvider and the usage of underlying addresses as
 *   index of the _interestRateData
 */
contract DefaultReserveInterestRateStrategyV2 is IDefaultInterestRateStrategyV2 {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  struct CalcInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 currentVariableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 borrowUsageRatio;
    uint256 supplyUsageRatio;
    uint256 availableLiquidityPlusDebt;
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  /// @inheritdoc IDefaultInterestRateStrategyV2
  uint256 public constant MAX_BORROW_RATE = 1000_00;

  /// @inheritdoc IDefaultInterestRateStrategyV2
  uint256 public constant MIN_OPTIMAL_POINT = 1_00;

  /// @inheritdoc IDefaultInterestRateStrategyV2
  uint256 public constant MAX_OPTIMAL_POINT = 99_00;

  /// @dev Map of reserves address and their interest rate data (reserveAddress => interestRateData)
  mapping(address => InterestRateData) internal _interestRateData;

  modifier onlyPoolConfigurator() {
    require(
      msg.sender == ADDRESSES_PROVIDER.getPoolConfigurator(),
      Errors.CallerNotPoolConfigurator()
    );
    _;
  }

  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider of the associated Aave pool
   */
  constructor(address provider) {
    require(provider != address(0), Errors.InvalidAddressesProvider());
    ADDRESSES_PROVIDER = IPoolAddressesProvider(provider);
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function setInterestRateParams(
    address reserve,
    bytes calldata rateData
  ) external onlyPoolConfigurator {
    _setInterestRateParams(reserve, abi.decode(rateData, (InterestRateData)));
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function setInterestRateParams(
    address reserve,
    InterestRateData calldata rateData
  ) external onlyPoolConfigurator {
    _setInterestRateParams(reserve, rateData);
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getInterestRateData(address reserve) external view returns (InterestRateDataRay memory) {
    return _rayifyRateData(_interestRateData[reserve]);
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getInterestRateDataBps(address reserve) external view returns (InterestRateData memory) {
    return _interestRateData[reserve];
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getOptimalUsageRatio(address reserve) external view returns (uint256) {
    return _bpsToRay(uint256(_interestRateData[reserve].optimalUsageRatio));
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getVariableRateSlope1(address reserve) external view returns (uint256) {
    return _bpsToRay(uint256(_interestRateData[reserve].variableRateSlope1));
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getVariableRateSlope2(address reserve) external view returns (uint256) {
    return _bpsToRay(uint256(_interestRateData[reserve].variableRateSlope2));
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getBaseVariableBorrowRate(address reserve) external view override returns (uint256) {
    return _bpsToRay(uint256(_interestRateData[reserve].baseVariableBorrowRate));
  }

  /// @inheritdoc IDefaultInterestRateStrategyV2
  function getMaxVariableBorrowRate(address reserve) external view override returns (uint256) {
    return
      _bpsToRay(
        uint256(
          _interestRateData[reserve].baseVariableBorrowRate +
            _interestRateData[reserve].variableRateSlope1 +
            _interestRateData[reserve].variableRateSlope2
        )
      );
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams calldata params
  ) external view virtual override returns (uint256, uint256) {
    InterestRateDataRay memory rateData = _rayifyRateData(_interestRateData[params.reserve]);

    CalcInterestRatesLocalVars memory vars;

    vars.currentLiquidityRate = 0;
    vars.currentVariableBorrowRate = rateData.baseVariableBorrowRate;

    if (params.totalDebt != 0) {
      vars.availableLiquidity =
        params.virtualUnderlyingBalance +
        params.liquidityAdded -
        params.liquidityTaken;

      vars.availableLiquidityPlusDebt = vars.availableLiquidity + params.totalDebt;
      vars.borrowUsageRatio = params.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
      vars.supplyUsageRatio = params.totalDebt.rayDiv(
        vars.availableLiquidityPlusDebt + params.unbacked
      );
    } else {
      return (0, vars.currentVariableBorrowRate);
    }

    if (vars.borrowUsageRatio > rateData.optimalUsageRatio) {
      uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - rateData.optimalUsageRatio).rayDiv(
        WadRayMath.RAY - rateData.optimalUsageRatio
      );

      vars.currentVariableBorrowRate +=
        rateData.variableRateSlope1 +
        rateData.variableRateSlope2.rayMul(excessBorrowUsageRatio);
    } else {
      vars.currentVariableBorrowRate += rateData
        .variableRateSlope1
        .rayMul(vars.borrowUsageRatio)
        .rayDiv(rateData.optimalUsageRatio);
    }

    vars.currentLiquidityRate = vars
      .currentVariableBorrowRate
      .rayMul(vars.supplyUsageRatio)
      .percentMul(PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor);

    return (vars.currentLiquidityRate, vars.currentVariableBorrowRate);
  }

  /**
   * @dev Doing validations and data update for an asset
   * @param reserve address of the underlying asset of the reserve
   * @param rateData Encoded reserve interest rate data to apply
   */
  function _setInterestRateParams(address reserve, InterestRateData memory rateData) internal {
    require(reserve != address(0), Errors.ZeroAddressNotValid());

    require(
      rateData.optimalUsageRatio <= MAX_OPTIMAL_POINT &&
        rateData.optimalUsageRatio >= MIN_OPTIMAL_POINT,
      Errors.InvalidOptimalUsageRatio()
    );

    require(
      rateData.variableRateSlope1 <= rateData.variableRateSlope2,
      Errors.Slope2MustBeGteSlope1()
    );

    // The maximum rate should not be above certain threshold
    require(
      uint256(rateData.baseVariableBorrowRate) +
        uint256(rateData.variableRateSlope1) +
        uint256(rateData.variableRateSlope2) <=
        MAX_BORROW_RATE,
      Errors.InvalidMaxRate()
    );

    _interestRateData[reserve] = rateData;
    emit RateDataUpdate(
      reserve,
      rateData.optimalUsageRatio,
      rateData.baseVariableBorrowRate,
      rateData.variableRateSlope1,
      rateData.variableRateSlope2
    );
  }

  /**
   * @dev Transforms an InterestRateData struct to an InterestRateDataRay struct by multiplying all values
   * by 1e23, turning them into ray values
   *
   * @param data The InterestRateData struct to transform
   *
   * @return The resulting InterestRateDataRay struct
   */
  function _rayifyRateData(
    InterestRateData memory data
  ) internal pure returns (InterestRateDataRay memory) {
    return
      InterestRateDataRay({
        optimalUsageRatio: _bpsToRay(uint256(data.optimalUsageRatio)),
        baseVariableBorrowRate: _bpsToRay(uint256(data.baseVariableBorrowRate)),
        variableRateSlope1: _bpsToRay(uint256(data.variableRateSlope1)),
        variableRateSlope2: _bpsToRay(uint256(data.variableRateSlope2))
      });
  }

  // @dev helper function added here, as generally the protocol doesn't use bps
  function _bpsToRay(uint256 n) internal pure returns (uint256) {
    return n * 1e23;
  }
}

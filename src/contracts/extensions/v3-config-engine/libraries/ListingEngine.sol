// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IPool, IDefaultInterestRateStrategyV2} from '../IAaveV3ConfigEngine.sol';
import {PriceFeedEngine} from './PriceFeedEngine.sol';
import {CapsEngine} from './CapsEngine.sol';
import {BorrowEngine} from './BorrowEngine.sol';
import {CollateralEngine} from './CollateralEngine.sol';
import {ConfiguratorInputTypes} from '../../../protocol/libraries/types/ConfiguratorInputTypes.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

library ListingEngine {
  using Address for address;
  using SafeCast for uint256;

  function executeCustomAssetListing(
    IEngine.PoolContext calldata context,
    IEngine.EngineConstants calldata engineConstants,
    IEngine.EngineLibraries calldata engineLibraries,
    IEngine.ListingWithCustomImpl[] calldata listings
  ) external {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    IEngine.RepackedListings memory repacked = _repackListing(listings);

    engineLibraries.priceFeedEngine.functionDelegateCall(
      abi.encodeWithSelector(
        PriceFeedEngine.executePriceFeedsUpdate.selector,
        engineConstants,
        repacked.priceFeedsUpdates
      )
    );

    _initAssets(
      context,
      engineConstants.poolConfigurator,
      repacked.ids,
      repacked.basics,
      repacked.rates
    );

    engineLibraries.capsEngine.functionDelegateCall(
      abi.encodeWithSelector(
        CapsEngine.executeCapsUpdate.selector,
        engineConstants,
        repacked.capsUpdates
      )
    );

    engineLibraries.borrowEngine.functionDelegateCall(
      abi.encodeWithSelector(
        BorrowEngine.executeBorrowSide.selector,
        engineConstants,
        repacked.borrowsUpdates
      )
    );

    engineLibraries.collateralEngine.functionDelegateCall(
      abi.encodeWithSelector(
        CollateralEngine.executeCollateralSide.selector,
        engineConstants,
        repacked.collateralsUpdates
      )
    );
  }

  function _repackListing(
    IEngine.ListingWithCustomImpl[] calldata listings
  ) internal pure returns (IEngine.RepackedListings memory) {
    address[] memory ids = new address[](listings.length);
    IEngine.BorrowUpdate[] memory borrowsUpdates = new IEngine.BorrowUpdate[](listings.length);
    IEngine.CollateralUpdate[] memory collateralsUpdates = new IEngine.CollateralUpdate[](
      listings.length
    );
    IEngine.PriceFeedUpdate[] memory priceFeedsUpdates = new IEngine.PriceFeedUpdate[](
      listings.length
    );
    IEngine.CapsUpdate[] memory capsUpdates = new IEngine.CapsUpdate[](listings.length);

    IEngine.Basic[] memory basics = new IEngine.Basic[](listings.length);
    IDefaultInterestRateStrategyV2.InterestRateData[]
      memory rates = new IDefaultInterestRateStrategyV2.InterestRateData[](listings.length);

    for (uint256 i = 0; i < listings.length; i++) {
      require(listings[i].base.asset != address(0), 'INVALID_ASSET');
      ids[i] = listings[i].base.asset;
      basics[i] = IEngine.Basic({
        assetSymbol: listings[i].base.assetSymbol,
        implementations: listings[i].implementations
      });
      priceFeedsUpdates[i] = IEngine.PriceFeedUpdate({
        asset: listings[i].base.asset,
        priceFeed: listings[i].base.priceFeed
      });
      borrowsUpdates[i] = IEngine.BorrowUpdate({
        asset: listings[i].base.asset,
        enabledToBorrow: listings[i].base.enabledToBorrow,
        flashloanable: listings[i].base.flashloanable,
        borrowableInIsolation: listings[i].base.borrowableInIsolation,
        withSiloedBorrowing: listings[i].base.withSiloedBorrowing,
        reserveFactor: listings[i].base.reserveFactor
      });
      collateralsUpdates[i] = IEngine.CollateralUpdate({
        asset: listings[i].base.asset,
        ltv: listings[i].base.ltv,
        liqThreshold: listings[i].base.liqThreshold,
        liqBonus: listings[i].base.liqBonus,
        debtCeiling: listings[i].base.debtCeiling,
        liqProtocolFee: listings[i].base.liqProtocolFee
      });
      capsUpdates[i] = IEngine.CapsUpdate({
        asset: listings[i].base.asset,
        supplyCap: listings[i].base.supplyCap,
        borrowCap: listings[i].base.borrowCap
      });
      rates[i] = IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: listings[i].base.rateStrategyParams.optimalUsageRatio.toUint16(),
        baseVariableBorrowRate: listings[i]
          .base
          .rateStrategyParams
          .baseVariableBorrowRate
          .toUint32(),
        variableRateSlope1: listings[i].base.rateStrategyParams.variableRateSlope1.toUint32(),
        variableRateSlope2: listings[i].base.rateStrategyParams.variableRateSlope2.toUint32()
      });
    }

    return
      IEngine.RepackedListings(
        ids,
        basics,
        borrowsUpdates,
        collateralsUpdates,
        priceFeedsUpdates,
        capsUpdates,
        rates
      );
  }

  /// @dev mandatory configurations for any asset getting listed, including oracle config and basic init
  function _initAssets(
    IEngine.PoolContext calldata context,
    IPoolConfigurator poolConfigurator,
    address[] memory ids,
    IEngine.Basic[] memory basics,
    IDefaultInterestRateStrategyV2.InterestRateData[] memory rates
  ) internal {
    ConfiguratorInputTypes.InitReserveInput[]
      memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](ids.length);

    for (uint256 i = 0; i < ids.length; i++) {
      initReserveInputs[i] = ConfiguratorInputTypes.InitReserveInput({
        aTokenImpl: basics[i].implementations.aToken,
        variableDebtTokenImpl: basics[i].implementations.vToken,
        interestRateData: abi.encode(rates[i]),
        underlyingAsset: ids[i],
        aTokenName: string.concat('Aave ', context.networkName, ' ', basics[i].assetSymbol),
        aTokenSymbol: string.concat('a', context.networkAbbreviation, basics[i].assetSymbol),
        variableDebtTokenName: string.concat(
          'Aave ',
          context.networkName,
          ' Variable Debt ',
          basics[i].assetSymbol
        ),
        variableDebtTokenSymbol: string.concat(
          'variableDebt',
          context.networkAbbreviation,
          basics[i].assetSymbol
        ),
        params: bytes('')
      });
    }
    poolConfigurator.initReserves(initReserveInputs);
  }
}

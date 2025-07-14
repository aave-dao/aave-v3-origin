// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ACLManager} from '../../contracts/protocol/configuration/ACLManager.sol';
import {IPoolConfigurator} from '../../contracts/interfaces/IPoolConfigurator.sol';
import {MarketReport} from '../interfaces/IMarketReportTypes.sol';
import {IAaveV3ConfigEngine as IEngine} from '../../contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {ConfiguratorInputTypes} from '../../contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {EngineFlags} from '../../contracts/extensions/v3-config-engine/EngineFlags.sol';
import {AaveV3Payload} from '../../contracts/extensions/v3-config-engine/AaveV3Payload.sol';

contract HorizonPhaseOneListing is AaveV3Payload {
  address public immutable ATOKEN_IMPLEMENTATION;
  address public immutable RWA_ATOKEN_IMPLEMENTATION;
  address public immutable VARIABLE_DEBT_TOKEN_IMPLEMENTATION;

  ACLManager public immutable ACL_MANAGER;
  IPoolConfigurator public immutable CONFIGURATOR;

  address public immutable GHO_ADDRESS;
  address public immutable GHO_PRICE_FEED;

  address public immutable USDC_ADDRESS;
  address public immutable USDC_PRICE_FEED;

  address public immutable RLUSD_ADDRESS;
  address public immutable RLUSD_PRICE_FEED;

  address public immutable USTB_ADDRESS;
  address public immutable USTB_PRICE_FEED;

  address public immutable USCC_ADDRESS;
  address public immutable USCC_PRICE_FEED;

  address public immutable USYC_ADDRESS;
  address public immutable USYC_PRICE_FEED;

  bytes32 public constant POOL_ADMIN_ROLE_ID =
    0x12ad05bde78c5ab75238ce885307f96ecd482bb402ef831f99e7018a0f169b7b;

  constructor(MarketReport memory report) AaveV3Payload(IEngine(report.configEngine)) {
    ATOKEN_IMPLEMENTATION = report.aToken;
    RWA_ATOKEN_IMPLEMENTATION = report.rwaAToken;
    VARIABLE_DEBT_TOKEN_IMPLEMENTATION = report.variableDebtToken;

    ACL_MANAGER = ACLManager(report.aclManager);
    require(report.poolConfiguratorProxy == address(CONFIG_ENGINE.POOL_CONFIGURATOR()));
    CONFIGURATOR = IPoolConfigurator(report.poolConfiguratorProxy);

    GHO_ADDRESS = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
    GHO_PRICE_FEED = 0xD110cac5d8682A3b045D5524a9903E031d70FCCd;

    USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    USDC_PRICE_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    RLUSD_ADDRESS = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
    RLUSD_PRICE_FEED = 0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A;

    USTB_ADDRESS = 0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e;
    USTB_PRICE_FEED = 0x289B5036cd942e619E1Ee48670F98d214E745AAC;

    USCC_ADDRESS = 0x14d60E7FDC0D71d8611742720E4C50E7a974020c;
    USCC_PRICE_FEED = 0xAfFd8F5578E8590665de561bdE9E7BAdb99300d9;

    USYC_ADDRESS = 0x136471a34f6ef19fE571EFFC1CA711fdb8E49f2b;
    USYC_PRICE_FEED = 0xE8E65Fb9116875012F5990Ecaab290B3531DbeB9;
  }

  // list a token with virtual accounting deactivated (ex. GHO)
  function _preExecute() internal override {
    ConfiguratorInputTypes.InitReserveInput[]
      memory reserves = new ConfiguratorInputTypes.InitReserveInput[](1);
    reserves[0] = ConfiguratorInputTypes.InitReserveInput({
      aTokenImpl: ATOKEN_IMPLEMENTATION,
      variableDebtTokenImpl: VARIABLE_DEBT_TOKEN_IMPLEMENTATION,
      useVirtualBalance: false,
      interestRateStrategyAddress: CONFIG_ENGINE.DEFAULT_INTEREST_RATE_STRATEGY(),
      underlyingAsset: GHO_ADDRESS,
      treasury: CONFIG_ENGINE.COLLECTOR(),
      incentivesController: CONFIG_ENGINE.REWARDS_CONTROLLER(),
      aTokenName: 'Aave Horizon RWA GHO', // todo: decide names, see ListingEngine
      aTokenSymbol: 'aHRwaGHO',
      variableDebtTokenName: 'Aave Horizon RWA Variable Debt GHO',
      variableDebtTokenSymbol: 'variableDebtHRwaGHO',
      params: bytes(''),
      interestRateData: abi.encode(
        IEngine.InterestRateInputData({
          optimalUsageRatio: 92_00,
          baseVariableBorrowRate: 3_50,
          variableRateSlope1: 1_25,
          variableRateSlope2: 35_00
        })
      )
    });
    CONFIGURATOR.initReserves(reserves);
  }

  function priceFeedsUpdates() public view override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory feeds = new IEngine.PriceFeedUpdate[](1);
    feeds[0] = IEngine.PriceFeedUpdate({asset: GHO_ADDRESS, priceFeed: GHO_PRICE_FEED});
    return feeds;
  }

  function borrowsUpdates() public view override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrows = new IEngine.BorrowUpdate[](1);
    borrows[0] = IEngine.BorrowUpdate({
      asset: GHO_ADDRESS,
      enabledToBorrow: EngineFlags.ENABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      reserveFactor: 15_00
    });
    return borrows;
  }

  function capsUpdates() public view override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory caps = new IEngine.CapsUpdate[](1);
    caps[0] = IEngine.CapsUpdate({asset: GHO_ADDRESS, supplyCap: 5_000_000, borrowCap: 4_000_000});
    return caps;
  }

  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](5);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: USDC_ADDRESS,
        assetSymbol: 'USDC',
        priceFeed: USDC_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 92_50,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 5_50,
          variableRateSlope2: 35_00
        }),
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: 0,
        liqThreshold: 0,
        liqBonus: 0,
        reserveFactor: 15_00,
        supplyCap: 5_000_000,
        borrowCap: 4_000_000,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    listingsCustom[1] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: RLUSD_ADDRESS,
        assetSymbol: 'RLUSD',
        priceFeed: RLUSD_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 80_00,
          baseVariableBorrowRate: 4_00,
          variableRateSlope1: 2_50,
          variableRateSlope2: 50_00
        }),
        enabledToBorrow: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.ENABLED,
        ltv: 0,
        liqThreshold: 0,
        liqBonus: 0,
        reserveFactor: 15_00,
        supplyCap: 5_000_000,
        borrowCap: 4_000_000,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    listingsCustom[2] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: USTB_ADDRESS,
        assetSymbol: 'USTB',
        priceFeed: USTB_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 99_00,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 0,
          variableRateSlope2: 0
        }),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 75_00,
        liqThreshold: 80_00,
        liqBonus: 12_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 3_000_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: RWA_ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    listingsCustom[3] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: USCC_ADDRESS,
        assetSymbol: 'USCC',
        priceFeed: USCC_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 99_00,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 0,
          variableRateSlope2: 0
        }),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 75_00,
        liqThreshold: 80_00,
        liqBonus: 12_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 3_000_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: RWA_ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    listingsCustom[4] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: USYC_ADDRESS,
        assetSymbol: 'USYC',
        priceFeed: USYC_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 99_00,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 0,
          variableRateSlope2: 0
        }),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 75_00,
        liqThreshold: 80_00,
        liqBonus: 12_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 3_000_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: RWA_ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    return listingsCustom;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Horizon RWA', networkAbbreviation: 'HRwa'});
  }

  function _postExecute() internal override {
    ACL_MANAGER.renounceRole(POOL_ADMIN_ROLE_ID, address(this));
  }
}

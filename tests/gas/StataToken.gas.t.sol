// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {PullRewardsTransferStrategy} from '../../src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {Testhelpers, TestnetERC20, IERC20} from './Testhelpers.sol';
import {StataTokenFactory} from '../../src/contracts/extensions/stata-token/StataTokenFactory.sol';
import {StataTokenV2} from '../../src/contracts/extensions/stata-token/StataTokenV2.sol';
import {DataTypes} from '../../src/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * Scenario suite for statatoken operations.
 */
contract StataToken_gas_Tests is Testhelpers {
  StataTokenV2 public stataToken;

  address public rewardTokenOne;
  address public rewardTokenTwo;
  address public emissionAdmin;
  PullRewardsTransferStrategy strategy;

  function setUp() public override {
    super.setUp();
    StataTokenFactory(report.staticATokenFactoryProxy).createStataTokens(
      contracts.poolProxy.getReservesList()
    );
    stataToken = StataTokenV2(
      StataTokenFactory(report.staticATokenFactoryProxy).getStataToken(tokenList.usdx)
    );

    emissionAdmin = vm.addr(1024);
    rewardTokenOne = address(new TestnetERC20('LM Reward ERC20 One', 'RWD_1', 18, poolAdmin));
    rewardTokenTwo = address(new TestnetERC20('LM Reward ERC20 Two', 'RWD_2', 18, poolAdmin));
    strategy = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      emissionAdmin,
      emissionAdmin
    );

    vm.startPrank(poolAdmin);
    contracts.emissionManager.setEmissionAdmin(rewardTokenOne, emissionAdmin);
    contracts.emissionManager.setEmissionAdmin(rewardTokenTwo, emissionAdmin);
    vm.stopPrank();
  }

  function test_deposit() external {
    uint256 amountToDeposit = 1000e8;
    deal(tokenList.usdx, address(this), amountToDeposit);
    IERC20(tokenList.usdx).approve(address(stataToken), amountToDeposit);

    uint256 shares = stataToken.deposit(amountToDeposit, address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'deposit');

    stataToken.redeem(shares, address(this), address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'redeem');
  }

  function test_depositATokens() external {
    uint256 amountToDeposit = 1000e8;
    _supplyOnReserve(address(this), amountToDeposit, tokenList.usdx);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    IERC20(reserveData.aTokenAddress).approve(address(stataToken), amountToDeposit);

    uint256 shares = stataToken.depositATokens(amountToDeposit, address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'depositATokens');

    stataToken.redeemATokens(shares, address(this), address(this));
    vm.snapshotGasLastCall('StataTokenV2', 'redeemAToken');
  }

  function test_claimRewards() external {
    uint256 amountToDeposit = 1000e8;
    _supplyOnReserve(address(this), amountToDeposit, tokenList.usdx);
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    IERC20(reserveData.aTokenAddress).approve(address(stataToken), amountToDeposit);
    stataToken.depositATokens(amountToDeposit, address(this));

    uint32 endTimestamp = uint32(vm.getBlockTimestamp() + 15 days);
    _setupEmission(
      rewardTokenOne,
      reserveData.aTokenAddress,
      endTimestamp,
      1e14,
      emissionAdmin,
      address(strategy)
    );
    _setupEmission(
      rewardTokenTwo,
      reserveData.aTokenAddress,
      endTimestamp,
      1e14,
      emissionAdmin,
      address(strategy)
    );
    stataToken.refreshRewardTokens();
    vm.warp(endTimestamp);

    address[] memory rewardTokens = new address[](2);
    rewardTokens[0] = rewardTokenOne;
    rewardTokens[1] = rewardTokenTwo;

    stataToken.claimRewards(address(this), rewardTokens);
    vm.snapshotGasLastCall('StataTokenV2', 'claimRewards');
  }
}

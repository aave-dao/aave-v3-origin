// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IRewardsController} from '../../../src/periphery/contracts/rewards/interfaces/IRewardsController.sol';
import {RewardsDataTypes} from '../../../src/periphery/contracts/rewards/libraries/RewardsDataTypes.sol';
import {PullRewardsTransferStrategy} from '../../../src/periphery/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {ITransferStrategyBase} from '../../../src/periphery/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../../src/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {IPool} from '../../../src/core/contracts/interfaces/IPool.sol';
import {StaticATokenFactory} from '../../../src/periphery/contracts/static-a-token/StaticATokenFactory.sol';
import {StaticATokenLM, IStaticATokenLM, IERC20, IERC20Metadata} from '../../../src/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {IAToken} from '../../../src/core/contracts/interfaces/IAToken.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {DataTypes} from '../../../src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

abstract contract BaseTest is TestnetProcedures {

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  address constant OWNER = address(1234);
  address public constant EMISSION_ADMIN = address(25);

  address public user;
  address public user1;
  address internal spender;

  uint256 internal userPrivateKey;
  uint256 internal spenderPrivateKey;

  StaticATokenLM public staticATokenLM;
  address public proxyAdmin;
  ITransparentProxyFactory public proxyFactory;
  StaticATokenFactory public factory;

  address[] rewardTokens;

  address public UNDERLYING;
  address public A_TOKEN;
  address public REWARD_TOKEN;
  IPool public POOL;

  function setUp() public virtual {
    userPrivateKey = 0xA11CE;
    spenderPrivateKey = 0xB0B0;
    user = address(vm.addr(userPrivateKey));
    user1 = address(vm.addr(2));
    spender = vm.addr(spenderPrivateKey);

    initTestEnvironment();
    DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(
      tokenList.weth
    );

    UNDERLYING = address(weth);
    REWARD_TOKEN = address(new TestnetERC20('LM Reward ERC20', 'RWD', 18, OWNER));
    A_TOKEN = reserveDataWETH.aTokenAddress;
    POOL = contracts.poolProxy;

    rewardTokens.push(REWARD_TOKEN);

    proxyFactory = ITransparentProxyFactory(report.transparentProxyFactory);
    proxyAdmin = report.proxyAdmin;

    factory = StaticATokenFactory(report.staticATokenFactoryProxy);
    factory.createStaticATokens(POOL.getReservesList());

    staticATokenLM = StaticATokenLM(factory.getStaticAToken(UNDERLYING));
  }

  function _configureLM() internal {
    PullRewardsTransferStrategy strat = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      EMISSION_ADMIN,
      EMISSION_ADMIN
    );

    vm.startPrank(poolAdmin);
    contracts.emissionManager.setEmissionAdmin(REWARD_TOKEN, EMISSION_ADMIN);
    vm.stopPrank();

    vm.startPrank(EMISSION_ADMIN);
    IERC20(REWARD_TOKEN).approve(address(strat), 10_000 ether);
    vm.stopPrank();

    vm.startPrank(OWNER);
    TestnetERC20(REWARD_TOKEN).mint(EMISSION_ADMIN, 10_000 ether);
    vm.stopPrank();

    RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](
      1
    );
    config[0] = RewardsDataTypes.RewardsConfigInput(
      0.00385 ether,
      10_000 ether,
      uint32(block.timestamp + 30 days),
      A_TOKEN,
      REWARD_TOKEN,
      ITransferStrategyBase(strat),
      IEACAggregatorProxy(address(2))
    );

    vm.prank(EMISSION_ADMIN);
    contracts.emissionManager.configureAssets(config);

    staticATokenLM.refreshRewardTokens();
  }

  function _fundUser(uint128 amountToDeposit, address targetUser) internal {
    deal(UNDERLYING, targetUser, amountToDeposit);
  }

  function _skipBlocks(uint128 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  function _underlyingToAToken(uint256 amountToDeposit, address targetUser) internal {
    IERC20(UNDERLYING).approve(address(POOL), amountToDeposit);
    POOL.deposit(UNDERLYING, amountToDeposit, targetUser, 0);
  }

  function _depositAToken(uint256 amountToDeposit, address targetUser) internal returns (uint256) {
    _underlyingToAToken(amountToDeposit, targetUser);
    IERC20(A_TOKEN).approve(address(staticATokenLM), amountToDeposit);
    return staticATokenLM.deposit(amountToDeposit, targetUser, 10, false);
  }

  function testAdmin() public {
    vm.stopPrank();
    vm.startPrank(proxyAdmin);
    assertEq(TransparentUpgradeableProxy(payable(address(staticATokenLM))).admin(), proxyAdmin);
    assertEq(TransparentUpgradeableProxy(payable(address(factory))).admin(), proxyAdmin);
    vm.stopPrank();
  }
}

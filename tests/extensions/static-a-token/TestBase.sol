// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IRewardsController} from 'src/contracts/rewards/interfaces/IRewardsController.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {StaticATokenFactory} from '../../../src/contracts/extensions/static-a-token/StaticATokenFactory.sol';
import {StaticATokenLM, IStaticATokenLM, IERC20, IERC20Metadata, ERC20} from '../../../src/contracts/extensions/static-a-token/StaticATokenLM.sol';
import {IAToken} from '../../../src/contracts/extensions/static-a-token/interfaces/IAToken.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

abstract contract BaseTest is TestnetProcedures {
  address constant OWNER = address(1234);

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
    DataTypes.ReserveDataLegacy memory reserveDataWETH = contracts.poolProxy.getReserveData(tokenList.weth);

    UNDERLYING = address(weth);
    REWARD_TOKEN = address(new TestnetERC20(
      'LM Reward ERC20',
      'RWD',
      18,
      OWNER
    ));
    A_TOKEN = reserveDataWETH.aTokenAddress;
    POOL = contracts.poolProxy;

    rewardTokens.push(REWARD_TOKEN);

    proxyFactory = ITransparentProxyFactory(report.transparentProxyFactory);
    proxyAdmin = report.proxyAdmin;

    factory = StaticATokenFactory(report.staticATokenFactoryProxy);
    factory.createStaticATokens(POOL.getReservesList());

    staticATokenLM = StaticATokenLM(factory.getStaticAToken(UNDERLYING));
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

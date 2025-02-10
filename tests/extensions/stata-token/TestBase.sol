// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {IERC20Metadata, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {StataTokenFactory} from '../../../src/contracts/extensions/stata-token/StataTokenFactory.sol';
import {StataTokenV2} from '../../../src/contracts/extensions/stata-token/StataTokenV2.sol';
import {IERC20AaveLM} from '../../../src/contracts/extensions/stata-token/interfaces/IERC20AaveLM.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';

abstract contract BaseTest is TestnetProcedures {
  /// @dev Storage slot with the admin of the contract.
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  address constant OWNER = address(1234);
  address public constant EMISSION_ADMIN = address(25);

  address public user;
  address public user1;
  address internal spender;

  uint256 internal userPrivateKey;
  uint256 internal spenderPrivateKey;

  StataTokenV2 public stataTokenV2;
  address public proxyAdmin;
  ITransparentProxyFactory public proxyFactory;
  StataTokenFactory public factory;

  address[] rewardTokens;

  address public underlying;
  address public aToken;
  address public rewardToken;

  function setUp() public virtual {
    userPrivateKey = 0xA11CE;
    spenderPrivateKey = 0xB0B0;
    user = address(vm.addr(userPrivateKey));
    user1 = address(vm.addr(2));
    spender = vm.addr(spenderPrivateKey);

    initTestEnvironment(false);

    underlying = address(weth);
    rewardToken = address(new TestnetERC20('LM Reward ERC20', 'RWD', 18, OWNER));
    aToken = contracts.poolProxy.getReserveAToken(tokenList.weth);

    rewardTokens.push(rewardToken);

    proxyFactory = ITransparentProxyFactory(report.transparentProxyFactory);

    factory = StataTokenFactory(report.staticATokenFactoryProxy);
    vm.expectRevert(Initializable.InvalidInitialization.selector);
    StataTokenFactory(report.staticATokenFactoryImplementation).initialize();
    factory.createStataTokens(contracts.poolProxy.getReservesList());

    stataTokenV2 = StataTokenV2(factory.getStataToken(underlying));
    proxyAdmin = address(uint160(uint256(vm.load(address(stataTokenV2), ADMIN_SLOT))));
  }

  function _skipBlocks(uint128 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  function _fundUnderlying(uint256 assets, address receiver) internal {
    deal(underlying, receiver, assets);
  }

  function _fundAToken(uint256 assets, address receiver) internal {
    _fundUnderlying(assets, receiver);
    vm.startPrank(receiver);
    IERC20(underlying).approve(address(contracts.poolProxy), assets);
    contracts.poolProxy.deposit(underlying, assets, receiver, 0);
    vm.stopPrank();
  }

  function _fund4626(uint256 assets, address receiver) internal returns (uint256) {
    _fundAToken(assets, receiver);
    vm.startPrank(receiver);
    IERC20(aToken).approve(address(stataTokenV2), assets);
    uint256 shares = stataTokenV2.depositATokens(assets, receiver);
    vm.stopPrank();
    return shares;
  }
}

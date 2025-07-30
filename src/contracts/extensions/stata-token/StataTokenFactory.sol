// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {IPool, DataTypes} from '../../../contracts/interfaces/IPool.sol';
import {StataTokenV2} from './StataTokenV2.sol';
import {IStataTokenFactory} from './interfaces/IStataTokenFactory.sol';

/**
 * @title StataTokenFactory
 * @notice Factory contract that keeps track of all deployed StataTokens for a specified pool.
 * This registry also acts as a factory, allowing to deploy new StataTokens on demand.
 * There can only be one StataToken per underlying on the registry at any time.
 * @author BGD labs
 */
contract StataTokenFactory is Initializable, IStataTokenFactory {
  ///@inheritdoc IStataTokenFactory
  IPool public immutable POOL;

  ///@inheritdoc IStataTokenFactory
  address public immutable INITIAL_OWNER;

  ///@inheritdoc IStataTokenFactory
  ITransparentProxyFactory public immutable TRANSPARENT_PROXY_FACTORY;

  ///@inheritdoc IStataTokenFactory
  address public immutable STATA_TOKEN_IMPL;

  mapping(address => address) internal _underlyingToStataToken;
  address[] internal _stataTokens;

  constructor(
    IPool pool,
    address initialOwner,
    ITransparentProxyFactory transparentProxyFactory,
    address stataTokenImpl
  ) {
    _disableInitializers();
    POOL = pool;
    INITIAL_OWNER = initialOwner;
    TRANSPARENT_PROXY_FACTORY = transparentProxyFactory;
    STATA_TOKEN_IMPL = stataTokenImpl;
  }

  function initialize() external initializer {}

  ///@inheritdoc IStataTokenFactory
  function createStataTokens(address[] memory underlyings) external returns (address[] memory) {
    address[] memory stataTokens = new address[](underlyings.length);
    for (uint256 i = 0; i < underlyings.length; i++) {
      address cachedStataToken = _underlyingToStataToken[underlyings[i]];
      if (cachedStataToken == address(0)) {
        address aTokenAddress = POOL.getReserveAToken(underlyings[i]);
        if (aTokenAddress == address(0)) revert NotListedUnderlying(aTokenAddress);
        bytes memory symbol = abi.encodePacked('w', IERC20Metadata(aTokenAddress).symbol());
        address stataToken = TRANSPARENT_PROXY_FACTORY.createDeterministic(
          STATA_TOKEN_IMPL,
          INITIAL_OWNER,
          abi.encodeWithSelector(
            StataTokenV2.initialize.selector,
            aTokenAddress,
            string(abi.encodePacked('Wrapped ', IERC20Metadata(aTokenAddress).name())),
            string(symbol)
          ),
          bytes32(uint256(uint160(underlyings[i])))
        );

        _underlyingToStataToken[underlyings[i]] = stataToken;
        stataTokens[i] = stataToken;
        _stataTokens.push(stataToken);
        emit StataTokenCreated(stataToken, underlyings[i]);
      } else {
        stataTokens[i] = cachedStataToken;
      }
    }
    return stataTokens;
  }

  ///@inheritdoc IStataTokenFactory
  function getStataTokens() external view returns (address[] memory) {
    return _stataTokens;
  }

  ///@inheritdoc IStataTokenFactory
  function getStataToken(address underlying) external view returns (address) {
    return _underlyingToStataToken[underlying];
  }
}

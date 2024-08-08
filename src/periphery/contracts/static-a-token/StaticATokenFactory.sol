// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool, DataTypes} from '../../../core/contracts/interfaces/IPool.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {StaticATokenLM} from './StaticATokenLM.sol';
import {IStaticATokenFactory} from './interfaces/IStaticATokenFactory.sol';

/**
 * @title StaticATokenFactory
 * @notice Factory contract that keeps track of all deployed static aToken wrappers for a specified pool.
 * This registry also acts as a factory, allowing to deploy new static aTokens on demand.
 * There can only be one static aToken per underlying on the registry at a time.
 * @author BGD labs
 */
contract StaticATokenFactory is Initializable, IStaticATokenFactory {
  IPool public immutable POOL;
  address public immutable PROXY_ADMIN;
  ITransparentProxyFactory public immutable TRANSPARENT_PROXY_FACTORY;
  address public immutable STATIC_A_TOKEN_IMPL;

  mapping(address => address) internal _underlyingToStaticAToken;
  address[] internal _staticATokens;

  event StaticTokenCreated(address indexed staticAToken, address indexed underlying);

  constructor(
    IPool pool,
    address proxyAdmin,
    ITransparentProxyFactory transparentProxyFactory,
    address staticATokenImpl
  ) {
    POOL = pool;
    PROXY_ADMIN = proxyAdmin;
    TRANSPARENT_PROXY_FACTORY = transparentProxyFactory;
    STATIC_A_TOKEN_IMPL = staticATokenImpl;
  }

  function initialize() external initializer {}

  ///@inheritdoc IStaticATokenFactory
  function createStaticATokens(address[] memory underlyings) external returns (address[] memory) {
    address[] memory staticATokens = new address[](underlyings.length);
    for (uint256 i = 0; i < underlyings.length; i++) {
      address cachedStaticAToken = _underlyingToStaticAToken[underlyings[i]];
      if (cachedStaticAToken == address(0)) {
        DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(underlyings[i]);
        require(reserveData.aTokenAddress != address(0), 'UNDERLYING_NOT_LISTED');
        bytes memory symbol = abi.encodePacked(
          'stat',
          IERC20Metadata(reserveData.aTokenAddress).symbol()
        );
        address staticAToken = TRANSPARENT_PROXY_FACTORY.createDeterministic(
          STATIC_A_TOKEN_IMPL,
          PROXY_ADMIN,
          abi.encodeWithSelector(
            StaticATokenLM.initialize.selector,
            reserveData.aTokenAddress,
            string(abi.encodePacked('Static ', IERC20Metadata(reserveData.aTokenAddress).name())),
            string(symbol)
          ),
          bytes32(uint256(uint160(underlyings[i])))
        );

        _underlyingToStaticAToken[underlyings[i]] = staticAToken;
        staticATokens[i] = staticAToken;
        _staticATokens.push(staticAToken);
        emit StaticTokenCreated(staticAToken, underlyings[i]);
      } else {
        staticATokens[i] = cachedStaticAToken;
      }
    }
    return staticATokens;
  }

  ///@inheritdoc IStaticATokenFactory
  function getStaticATokens() external view returns (address[] memory) {
    return _staticATokens;
  }

  ///@inheritdoc IStaticATokenFactory
  function getStaticAToken(address underlying) external view returns (address) {
    return _underlyingToStaticAToken[underlying];
  }
}

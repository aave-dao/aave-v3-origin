// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {IPool, IPoolAddressesProvider} from '../../../interfaces/IPool.sol';

interface IStataTokenFactory {
  event StataTokenCreated(address indexed stataToken, address indexed underlying);

  error NotListedUnderlying(address underlying);

  /**
   * @notice The pool associated with the factory.
   * @return The pool address.
   */
  function POOL() external view returns (IPool);

  /**
   * @notice The initial owner used for all tokens created via the factory.
   * @return The address of the initial owner.
   */
  function INITIAL_OWNER() external view returns (address);

  /**
   * @notice The proxy factory used for all tokens created via the stata factory.
   * @return The proxy factory address.
   */
  function TRANSPARENT_PROXY_FACTORY() external view returns (ITransparentProxyFactory);

  /**
   * @notice The stata implementation used for all tokens created via the factory.
   * @return The implementation address.
   */
  function STATA_TOKEN_IMPL() external view returns (address);

  /**
   * @notice Creates new StataTokens
   * @param underlyings the addresses of the underlyings to create.
   * @return address[] addresses of the new StataTokens.
   */
  function createStataTokens(address[] memory underlyings) external returns (address[] memory);

  /**
   * @notice Returns all StataTokens deployed via this registry.
   * @return address[] list of StataTokens
   */
  function getStataTokens() external view returns (address[] memory);

  /**
   * @notice Returns the StataToken for a given underlying.
   * @param underlying the address of the underlying.
   * @return address the StataToken address.
   */
  function getStataToken(address underlying) external view returns (address);
}

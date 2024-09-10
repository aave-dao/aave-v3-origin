// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IPool, DataTypes} from '../../lib/aave-helpers/lib/aave-address-book/src/AaveV3.sol';
import {IERC20Metadata} from '../../lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {ITransparentProxyFactory} from '../../lib/aave-helpers/lib/solidity-utils/src/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {Ownable} from '../../lib/aave-helpers/lib/solidity-utils/src/contracts/oz-common/Ownable.sol';

interface IStaticATokenFactory {
  /**
   * @notice Creates new staticATokens
   * @param underlyings the addresses of the underlyings to create.
   * @return address[] addresses of the new staticATokens.
   */
  function createStaticATokens(address[] memory underlyings) external returns (address[] memory);

  /**
   * @notice Returns all tokens deployed via this registry.
   * @return address[] list of tokens
   */
  function getStaticATokens() external view returns (address[] memory);

  /**
   * @notice Returns the staticAToken for a given underlying.
   * @param underlying the address of the underlying.
   * @return address the staticAToken address.
   */
  function getStaticAToken(address underlying) external view returns (address);
}

/**
 * @dev OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/tree/8b778fa20d6d76340c5fac1ed66c80273f05b95a
 *
 * BGD Labs adaptations:
 * - Linting
 */

pragma solidity ^0.8.0;

import 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
interface IProxyAdmin is IOwnable {
  function getProxyImplementation(
    TransparentUpgradeableProxy proxy
  ) external view returns (address);

  function getProxyAdmin(TransparentUpgradeableProxy proxy) external view returns (address);

  function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) external;

  function upgrade(TransparentUpgradeableProxy proxy, address implementation) external;

  function upgradeAndCall(
    TransparentUpgradeableProxy proxy,
    address implementation,
    bytes memory data
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';

contract TestnetRWAERC20 is TestnetERC20 {
  mapping(address => bool) public authorized;

  modifier onlyAuthorized(address account) {
    require(authorized[account], 'UNAUTHORIZED_RWA_ACCOUNT');
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    address owner
  ) TestnetERC20(name, symbol, decimals, owner) {}

  function authorize(address account, bool isAuthorized) public {
    authorized[account] = isAuthorized;
  }

  function _mint(
    address account,
    uint256 amount
  ) internal virtual override onlyAuthorized(account) {
    super._mint(account, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override onlyAuthorized(sender) onlyAuthorized(recipient) {
    super._transfer(sender, recipient, amount);
  }
}

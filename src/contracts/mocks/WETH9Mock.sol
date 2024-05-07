// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH9} from '../dependencies/weth/WETH9.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

contract WETH9Mock is WETH9, Ownable {
  constructor(string memory mockName, string memory mockSymbol, address owner) {
    name = mockName;
    symbol = mockSymbol;

    transferOwnership(owner);
  }

  function mint(address account, uint256 value) public onlyOwner returns (bool) {
    balanceOf[account] += value;
    emit Transfer(address(0), account, value);
    return true;
  }
}

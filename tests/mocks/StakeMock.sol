// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract StakeMock {
  event TestCheck(address a, uint256 b);
  event TestApproval(address spender, uint256 amount);

  function stake(address a, uint256 b) external {
    emit TestCheck(a, b);
  }

  function STAKED_TOKEN() public view returns (address) {
    return address(this);
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    emit TestApproval(spender, amount);
    return true;
  }
}

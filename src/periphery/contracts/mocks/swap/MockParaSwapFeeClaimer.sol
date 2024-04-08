// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFeeClaimer} from '../../adapters/paraswap/interfaces/IFeeClaimer.sol';
import {MockParaSwapTokenTransferProxy} from './MockParaSwapTokenTransferProxy.sol';
import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {MintableERC20} from 'aave-v3-core/contracts/mocks/tokens/MintableERC20.sol';

contract MockParaSwapFeeClaimer is IFeeClaimer {
  MockParaSwapTokenTransferProxy immutable TOKEN_TRANSFER_PROXY;

  mapping(address => mapping(address => uint256)) internal _fees;

  constructor() {
    TOKEN_TRANSFER_PROXY = new MockParaSwapTokenTransferProxy();
  }

  function registerFee(address _account, IERC20 _token, uint256 _fee) external {
    _fees[_account][address(_token)] += _fee;
  }

  function withdrawAllERC20(IERC20 _token, address _recipient) public returns (bool) {
    uint256 fees = _fees[address(msg.sender)][address(_token)];
    MintableERC20(address(_token)).mint(fees);
    IERC20(_token).transfer(_recipient, fees);
    _fees[address(msg.sender)][address(_token)] = 0;
    return true;
  }

  function batchWithdrawAllERC20(
    address[] calldata _tokens,
    address _recipient
  ) external returns (bool) {
    for (uint256 i = 0; i < _tokens.length; i++) {
      withdrawAllERC20(IERC20(_tokens[i]), _recipient);
    }
    return true;
  }

  function getBalance(IERC20 _token, address _partner) public view returns (uint256) {
    return _fees[_partner][address(_token)];
  }

  function batchGetBalance(
    address[] calldata _tokens,
    address _partner
  ) external view returns (uint256[] memory) {
    uint256[] memory fees = new uint256[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      fees[i] = getBalance(IERC20(_tokens[i]), _partner);
    }
    return fees;
  }

  function getUnallocatedFees(IERC20) external pure returns (uint256) {
    require(false, 'MOCK_NOT_IMPLEMENTED');
    return 0;
  }

  function withdrawSomeERC20(IERC20, uint256, address) external pure returns (bool) {
    require(false, 'MOCK_NOT_IMPLEMENTED');
    return false;
  }

  function batchWithdrawSomeERC20(
    IERC20[] calldata,
    uint256[] calldata,
    address
  ) external pure returns (bool) {
    require(false, 'MOCK_NOT_IMPLEMENTED');
    return false;
  }
}

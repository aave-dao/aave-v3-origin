// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

interface IFeeClaimer {
  /**
   * @notice register partner's, affiliate's and PP's fee
   * @dev only callable by AugustusSwapper contract
   * @param _account account address used to withdraw fees
   * @param _token token address
   * @param _fee fee amount in token
   */
  function registerFee(address _account, IERC20 _token, uint256 _fee) external;

  /**
   * @notice claim partner share fee in ERC20 token
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _token address of the ERC20 token
   * @param _recipient address
   * @return true if the withdraw was successfull
   */
  function withdrawAllERC20(IERC20 _token, address _recipient) external returns (bool);

  /**
   * @notice batch claim whole balance of fee share amount
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _tokens list of addresses of the ERC20 token
   * @param _recipient address of recipient
   * @return true if the withdraw was successfull
   */
  function batchWithdrawAllERC20(
    address[] calldata _tokens,
    address _recipient
  ) external returns (bool);

  /**
   * @notice claim some partner share fee in ERC20 token
   * @dev transfers ERC20 token amount to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _token address of the ERC20 token
   * @param _recipient address
   * @return true if the withdraw was successfull
   */
  function withdrawSomeERC20(
    IERC20 _token,
    uint256 _tokenAmount,
    address _recipient
  ) external returns (bool);

  /**
   * @notice batch claim some amount of fee share in ERC20 token
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _tokens address of the ERC20 tokens
   * @param _tokenAmounts array of amounts
   * @param _recipient destination account addresses
   * @return true if the withdraw was successfull
   */
  function batchWithdrawSomeERC20(
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenAmounts,
    address _recipient
  ) external returns (bool);

  /**
   * @notice compute unallocated fee in token
   * @param _token address of the ERC20 token
   * @return amount of unallocated token in fees
   */
  function getUnallocatedFees(IERC20 _token) external view returns (uint256);

  /**
   * @notice returns unclaimed fee amount given the token
   * @dev retrieves the balance of ERC20 token fee amount for a partner
   * @param _token address of the ERC20 token
   * @param _partner account address of the partner
   * @return amount of balance
   */
  function getBalance(IERC20 _token, address _partner) external view returns (uint256);

  /**
   * @notice returns unclaimed fee amount given the token in batch
   * @dev retrieves the balance of ERC20 token fee amount for a partner in batch
   * @param _tokens list of ERC20 token addresses
   * @param _partner account address of the partner
   * @return _fees array of the token amount
   */
  function batchGetBalance(
    address[] calldata _tokens,
    address _partner
  ) external view returns (uint256[] memory _fees);
}

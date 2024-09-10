// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

library StaticATokenErrors {
  string public constant INVALID_OWNER = '1';
  string public constant INVALID_EXPIRATION = '2';
  string public constant INVALID_SIGNATURE = '3';
  string public constant INVALID_DEPOSITOR = '4';
  string public constant INVALID_RECIPIENT = '5';
  string public constant INVALID_CLAIMER = '6';
  string public constant ONLY_ONE_AMOUNT_FORMAT_ALLOWED = '7';
  string public constant INVALID_ZERO_AMOUNT = '8';
  string public constant REWARD_NOT_INITIALIZED = '9';
}

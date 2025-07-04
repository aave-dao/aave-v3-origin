// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {IERC1271} from '../../src/contracts/extensions/sgho/sGHO.sol';

contract MockERC1271 is IERC1271 {
    bytes32 public constant MOCK_VALID_SIGNATURE_HASH = keccak256("VALID_SIGNATURE");

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        pure
        override
        returns (bytes4)
    {
        if (keccak256(_signature) == MOCK_VALID_SIGNATURE_HASH) {
            return IERC1271.isValidSignature.selector;
        }
        return bytes4(0);
    }
} 
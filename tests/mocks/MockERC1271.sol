// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

interface IERC1271 {
  function isValidSignature(bytes32, bytes memory) external view returns (bytes4);
}

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
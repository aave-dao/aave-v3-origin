// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library EIP712SigUtils {
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public constant DELEGATION_WITH_SIG_TYPEHASH =
    keccak256('DelegationWithSig(address delegatee,uint256 value,uint256 nonce,uint256 deadline)');

  bytes32 public constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  function getDomainSeparator(
    bytes memory name,
    bytes memory revision,
    address contractAddress
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          EIP712_DOMAIN,
          keccak256(name),
          keccak256(revision),
          block.chainid,
          contractAddress
        )
      );
  }

  struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  struct CreditDelegation {
    address delegatee;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  // computes the hash of a permit
  function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          _permit.owner,
          _permit.spender,
          _permit.value,
          _permit.nonce,
          _permit.deadline
        )
      );
  }

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getTypedDataHash(
    Permit memory _permit,
    bytes memory name,
    bytes memory revision,
    address contractAddress
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          getDomainSeparator(name, revision, contractAddress),
          getStructHash(_permit)
        )
      );
  }

  function getCreditDelegationStructHash(
    CreditDelegation memory _del
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          DELEGATION_WITH_SIG_TYPEHASH,
          _del.delegatee,
          _del.value,
          _del.nonce,
          _del.deadline
        )
      );
  }

  function getCreditDelegationTypedDataHash(
    CreditDelegation memory _del,
    bytes memory name,
    bytes memory revision,
    address contractAddress
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          getDomainSeparator(name, revision, contractAddress),
          getCreditDelegationStructHash(_del)
        )
      );
  }
}

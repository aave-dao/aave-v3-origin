//SPDX-License-Identifier: Unlicense
// Modified from https://github.com/0xsequence/create3/blob/5a4a152e6be4e0ecfbbbe546992a5aaa43a4c1b0/contracts/Create3.sol by Agustin Aguilar <aa@horizon.io>
pragma solidity ^0.8.0;

/**
 * @title A library for deploying contracts EIP-3171 style.
 * @author BGD Labs
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN

      <--- CODE --->

      0x00    0x36         0x36      CALLDATASIZE      cds
      0x01    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x02    0x80         0x80      DUP1              0 0 cds
      0x03    0x37         0x37      CALLDATACOPY
      0x04    0x36         0x36      CALLDATASIZE      cds
      0x05    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x06    0x34         0x34      CALLVALUE         val 0 cds
      0x07    0xf0         0xf0      CREATE            addr
      0x08    0xff         0xff      SELFDESTRUCT
  */
  bytes internal constant PROXY_CHILD_BYTECODE =
    hex'63_00_00_00_09_80_60_0E_60_00_39_60_00_F3_36_3d_80_37_36_3d_34_f0_ff';

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE =
    0x68afe50fe78ae96feb6ec11f21f31fdd467c9fcc7add426282cfa3913daf04e9;

  /**
   * @notice Returns the size of the code on a given address
   * @param addr Address that may or may not contain code
   * @return size of the code on the given `_addr`
   */
  function codeSize(address addr) internal view returns (uint256 size) {
    assembly {
      size := extcodesize(addr)
    }
  }

  /**
   * @notice Creates a new contract with given `_creationCode` and `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
   * @return address of the deployed contract, reverts on error
   */
  function create3(
    bytes32 salt,
    bytes memory creationCode
  ) internal returns (address) {
    return create3(salt, creationCode, 0);
  }

  /**
   * @notice Creates a new contract with given `_creationCode` and `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
   * @param value In WEI of ETH to be forwarded to child contract
   * @return addr of the deployed contract, reverts on error
   */
  function create3(
    bytes32 salt,
    bytes memory creationCode,
    uint256 value
  ) internal returns (address) {
    // Creation code
    bytes memory proxyCreationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    address deployedContract = addressOf(salt);
    if (codeSize(deployedContract) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy;
    assembly {
      proxy := create2(
        value,
        add(proxyCreationCode, 32),
        mload(proxyCreationCode),
        salt
      )
    }
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success, ) = proxy.call(creationCode);
    if (!success || codeSize(deployedContract) == 0) revert ErrorCreatingContract();
    return deployedContract;
  }

  /**
   * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @return address of the deployed contract, reverts on error
   * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
   */
  function addressOf(bytes32 salt) internal view returns (address) {
    return addressOfWithPreDeployedFactory(salt, address(this));
  }

  /**
   * @notice Computes the resulting address of a contract deployed using address of pre-deployed factory and the given `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param preDeployedFactory address of a pre deployed create 3 factory (its the address that will be used to create the proxy)
   * @return address of the deployed contract, reverts on error
   * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(preDeployedFactory) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
   */
  function addressOfWithPreDeployedFactory(
    bytes32 salt,
    address preDeployedFactory
  ) internal pure returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              preDeployedFactory,
              salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return
      address(
        uint160(
          uint256(keccak256(abi.encodePacked(hex'd6_94', proxy, hex'01')))
        )
      );
  }
}

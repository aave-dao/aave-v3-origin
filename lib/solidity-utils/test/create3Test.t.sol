// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Create3Factory, ICreate3Factory, Create3} from '../src/contracts/create3/Create3Factory.sol';
import {Ownable} from '../src/contracts/oz-common/Ownable.sol';

contract MockContract is Ownable {
  address public immutable SOME_ADDRESS;
  address internal _someOtherAddress;

  constructor(address someAddress, address owner) {
    SOME_ADDRESS = someAddress;
    _transferOwnership(owner);
  }

  function getOtherAddress() external view returns (address) {
    return _someOtherAddress;
  }

  function initialize(address someOtherAddress, address owner) external {
    _someOtherAddress = someOtherAddress;
    _transferOwnership(owner);
  }
}

contract Create3FactoryTest is Test {
  bytes32 public constant CREATE3_FACTORY_SALT = keccak256(bytes('Create3 Factory'));
  ICreate3Factory public factory;

  function setUp() public {
    factory = new Create3Factory{salt: CREATE3_FACTORY_SALT}();
  }

  function testCreate3WithoutValue(
    address someAddress,
    address owner,
    bytes32 salt
  ) public {
    bytes memory encodedParams = abi.encode(someAddress, owner);
    bytes memory code = type(MockContract).creationCode;
    // deploy Voting portal
    address votingPortal = factory.create(salt, abi.encodePacked(code, encodedParams));

    assertEq(votingPortal, factory.predictAddress(address(this), salt));
    assertEq(
      votingPortal,
      Create3.addressOfWithPreDeployedFactory(
        keccak256(abi.encodePacked(address(this), salt)),
        address(factory)
      )
    );
    assertEq(MockContract(votingPortal).owner(), owner);
    assertEq(MockContract(votingPortal).SOME_ADDRESS(), someAddress);
  }

  function testCreate3WithValue(
    address someAddress,
    address owner,
    address creator
  ) public {
    bytes memory encodedParams = abi.encode(someAddress, owner);
    bytes memory code = type(MockContract).creationCode;
    bytes32 salt = keccak256(bytes('Voting portal eth-avax-2'));
    // deploy Voting portal
    hoax(creator, 10 ether);
    address votingPortal = factory.create{value: 3 ether}(
      salt,
      abi.encodePacked(code, encodedParams)
    );

    assertEq(votingPortal, factory.predictAddress(creator, salt));
    assertEq(creator.balance, 7 ether);
    assertEq(votingPortal.balance, 3 ether);
  }
}

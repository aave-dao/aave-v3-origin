// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {ATokenInstance} from '../../src/contracts/instances/ATokenInstance.sol';
import {Vm} from 'forge-std/Vm.sol';

contract MockATokenInstance is ATokenInstance {
  Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256('hevm cheat code'))))));

  constructor(IPool pool, uint256 mockRevision) ATokenInstance(pool) {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('ATOKEN_REVISION()'),
      abi.encode(mockRevision)
    );
  }

  function getMockRevision() internal view returns (uint256) {
    return this.ATOKEN_REVISION();
  }

  /// @dev We use _cast to convert the view function to a pure function
  /// This allows us to perform an external call to ATOKEN_REVISION(),
  /// which is mocked in the constructor.
  function getRevision() internal pure virtual override returns (uint256) {
    return _cast(getMockRevision)();
  }

  function _cast(
    function() view returns (uint256) f
  ) internal pure returns (function() pure returns (uint256) f2) {
    assembly {
      f2 := f
    }
  }
}

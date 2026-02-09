// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

// Invariant Contracts
import {BaseInvariants} from './invariants/BaseInvariants.t.sol';

/// @title Invariants
/// @notice Wrappers for the protocol invariants implemented in each invariants contract
/// @dev recognised by Echidna when property mode is activated
/// @dev Inherits BaseInvariants
abstract contract Invariants is BaseInvariants {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                     BASE INVARIANTS                                       //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function echidna_BASE_INVARIANT_A() public returns (bool) {
    for (uint256 i; i < debtTokens.length; ++i) {
      assert_BASE_INVARIANT_A(IERC20(debtTokens[i]));
    }
    return true;
  }

  function echidna_BASE_INVARIANT_A_EXACT() public returns (bool) {
    for (uint256 i; i < debtTokens.length; ++i) {
      assert_BASE_INVARIANT_A_EXACT(IERC20(debtTokens[i]));
    }
    return true;
  }

  function echidna_BASE_INVARIANT_B() public returns (bool) {
    for (uint256 i; i < aTokens.length; ++i) {
      assert_BASE_INVARIANT_B(IERC20(aTokens[i]));
    }
    return true;
  }

  function echidna_BASE_INVARIANT_B_EXACT() public returns (bool) {
    for (uint256 i; i < aTokens.length; ++i) {
      assert_BASE_INVARIANT_B_EXACT(IERC20(aTokens[i]));
    }
    return true;
  }

  function echidna_BASE_INVARIANT_C() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BASE_INVARIANT_C(baseAssets[i]);
    }
    return true;
  }

  function echidna_BASE_INVARIANT_D() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BASE_INVARIANT_D(baseAssets[i]);
    }
    return true;
  }

  function echidna_BASE_INVARIANT_E() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BASE_INVARIANT_E(baseAssets[i]);
    }
    return true;
  }

  function echidna_BASE_INVARIANT_F() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BASE_INVARIANT_F(baseAssets[i]);
    }
    return true;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                        BORROWING                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function echidna_BORROWING_INVARIANT_A() public returns (bool) {
    for (uint256 i; i < debtTokens.length; ++i) {
      assert_BORROWING_INVARIANT_A(IERC20(debtTokens[i]));
    }
    return true;
  }

  function echidna_BORROWING_INVARIANT_B() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BORROWING_INVARIANT_B(baseAssets[i]);
    }
    return true;
  }

  function echidna_BORROWING_INVARIANT_C() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BORROWING_INVARIANT_C(baseAssets[i]);
    }
    return true;
  }

  function echidna_BORROWING_INVARIANT_D() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_BORROWING_INVARIANT_D(baseAssets[i]);
    }
    return true;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         ORACLE                                            //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function echidna_ORACLE_INVARIANT_A() public returns (bool) {
    assert_ORACLE_INVARIANT_A();
    return true;
  }

  function echidna_ORACLE_INVARIANT_B() public returns (bool) {
    assert_ORACLE_INVARIANT_B();
    return true;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                  INTEREST RATE STRATEGY                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////
  function echidna_IR_INVARIANT_A() public returns (bool) {
    for (uint256 i; i < baseAssets.length; ++i) {
      assert_IR_INVARIANT_A(baseAssets[i]);
    }
    return true;
  }
}

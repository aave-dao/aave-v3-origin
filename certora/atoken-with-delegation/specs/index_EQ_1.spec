import "base_token_v3.spec";

/*==============================================================================================
  In this file we prove that all the calls to rayMul(a,b), and rayDiv(a,b) are done with b==RAY().
  This is true only under the assumption that the asset has index==1.
  =============================================================================================*/

using SymbolicLendingPoolL1 as _SymbolicLendingPoolL1;

methods {
  function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256)  => index();
  function _.rayMul(uint256 a,uint256 b) internal => rayMulCVL_with_assert(a,b) expect uint256 ALL;
  function _.rayDiv(uint256 a,uint256 b) internal => rayDivCVL_with_assert(a,b) expect uint256 ALL;
  
  function getPreviousIndex(address user) external returns (uint256) envfree;
}

ghost index() returns uint256 {
    axiom index()==RAY();
}

function rayMulCVL_with_assert(uint256 a, uint256 b) returns uint256 {
  assert b==RAY();
  mathint ret = (a*b + RAY()/2) / RAY(); // We check in rayMulDiv.spec that this implementation is equivalent to the
                                         // "real" rayMul.
  assert ret==a;
  return a;
}

function rayDivCVL_with_assert(uint256 a, uint256 b) returns uint256 {
  assert b==RAY();
  mathint ret = (a*RAY()+b/2) / b; // We check in rayMulDiv.spec that this implementation is equivalent to the
                                   // "real" rayDiv.
  assert ret==a;
  return a;
}


definition is_harness_function(method f) returns bool =
  f.selector == sig:rayMul_WRP(uint256,uint256).selector ||
  f.selector == sig:rayDiv_WRP(uint256,uint256).selector
    ;


// =========================================================================
//   mirror_additionalData
// =========================================================================
persistent ghost mapping(address => uint128) mirror_additionalData { 
  init_state axiom forall address a. mirror_additionalData[a] == RAY();
}
hook Sstore _userState[KEY address a].additionalData uint128 newVal (uint128 oldVal) {
    mirror_additionalData[a] = newVal;
}
hook Sload uint128 val _userState[KEY address a].additionalData {
    require(mirror_additionalData[a] == val);
}

//invariant mirror_additionalData_correct(address a)
//    mirror_additionalData[a] == getPreviousIndex(a);


rule index_equals_one(method f) filtered {f-> f.contract == currentContract && !is_harness_function(f)} {
  calldataarg args;  env e;
  requireInvariant additionalData_EQ_RAY();
  
  if (f.selector == sig:mintToTreasury(uint256,uint256).selector) {
    uint256 amount; uint256 index_;
    require index_==RAY();
    mintToTreasury(e,amount,index_);
  }
  else if (f.selector == sig:mint(address,address,uint256,uint256).selector) {
    address caller; address onBehalfOf; uint256 scaledAmount; uint256 index_;
    require index_==RAY();
    mint(e,caller,onBehalfOf,scaledAmount,index_);
  }
  else if (f.selector == sig:burn(address,address,uint256,uint256,uint256).selector) {
    address caller; address onBehalfOf; uint256 amount; uint256 scaledAmount; uint256 index_;
    require index_==RAY();
    burn(e,caller,onBehalfOf,amount,scaledAmount,index_);
  }
  else if (f.selector == sig:transferOnLiquidation(address,address,uint256,uint256,uint256).selector) {
    address caller; address onBehalfOf; uint256 amount; uint256 scaledAmount; uint256 index_;
    require index_==RAY();
    transferOnLiquidation(e,caller,onBehalfOf,amount,scaledAmount,index_);
  }
  else
    f(e,args);
  
  assert true;
}


invariant additionalData_EQ_RAY()
  forall address u. mirror_additionalData[u]== RAY()
  filtered {f ->  f.contract == currentContract && !is_harness_function(f)}
{
  preserved mintToTreasury(uint256 amount, uint256 index_) with (env e1) {
    require index_==RAY();
  }
  preserved mint(address caller, address onBehalfOf, uint256 scaledAmount, uint256 index_) with (env e2) {
    require index_==RAY();
  }
  preserved burn(address caller, address onBehalfOf, uint256 amount, uint256 scaledAmount, uint256 index_) with (env e3) {
    require index_==RAY();
  }
  preserved transferOnLiquidation(address caller, address onBehalfOf, uint256 amount, uint256 scaledAmount, uint256 index_) with (env e4) {
    require index_==RAY();
  }
}


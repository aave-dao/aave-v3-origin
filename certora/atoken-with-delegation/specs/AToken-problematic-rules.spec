

/*=============================================================================================
  The rules of this file were part of the file AToken.spec.
  The reason for the separation is that the rules of this file are timed-out if not 
  run separately.
  Hence, in the CI we run all the rules of AToken.spec simultaneously, and each rule of
  this file alone.
  =============================================================================================*/



/**

- values of gRNI passing: ray, 2 * ray

*/

using DummyERC20_aTokenUnderlying as _underlyingAsset;

methods { 
    function nonces(address) external returns (uint256) envfree;
    function allowance(address, address) external returns (uint256) envfree;
    function _.handleAction(address, uint256, uint256) external => NONDET;
    function _.getReserveNormalizedIncome(address u) external => gRNI() expect uint256 ALL;
    function balanceOf(address) external returns (uint256) envfree;
    function additionalData(address) external returns uint128 envfree;
    function _.finalizeTransfer(address, address, address, uint256, uint256, uint256) external => NONDET;
    
    function scaledTotalSupply() external returns (uint256);
    function scaledBalanceOf(address) external returns (uint256);
    function scaledBalance_to_balance(uint256) external returns (uint256) envfree;
}



function PLUS256(uint256 x, uint256 y) returns uint256 {
    return (assert_uint256( (x+y) % 2^256) ) ;
}
function MINUS256(uint256 x, uint256 y) returns uint256 {
    return (assert_uint256( (x-y) % 2^256) );
}

/*
function PLUS256(uint256 x, uint256 y) returns uint256 {
    return require_uint256(x+y);
}
function MINUS256(uint256 x, uint256 y) returns uint256 {
    return require_uint256(x-y);
}
*/

definition ray() returns uint = 1000000000000000000000000000;
//definition half_ray() returns uint = ray() / 2;
definition bound() returns mathint = ((gRNI() / ray()) + 1 ) / 2;

/*
Due to rayDiv and RayMul Rounding (+ 0.5) - blance could increase by (gRNI() / Ray() + 1) / 2.
*/
definition bounded_error_eq(uint x, uint y, uint scale) returns bool =
    to_mathint(x) <= to_mathint(y) + (bound() * scale)
    &&
    to_mathint(x) + (bound() * scale) >= to_mathint(y);

persistent ghost sumAllBalance() returns mathint {
    init_state axiom sumAllBalance() == 0;
}

// summerization for scaledBlanaceOf -> regularBalanceOf + 0.5 (canceling the rayMul)
ghost gRNI() returns uint256 {
    axiom to_mathint(gRNI()) == 7 * ray();
}

hook Sstore _userState[KEY address a].balance uint120 balance (uint120 old_balance) {
    havoc sumAllBalance assuming sumAllBalance@new() == sumAllBalance@old() + balance - old_balance;
}


invariant totalSupplyEqualsSumAllBalance(env e)
    totalSupply(e) == scaledBalance_to_balance(require_uint256(sumAllBalance()))
    filtered { f -> !f.isView && f.contract == currentContract}
/*
    {
        preserved mint(address caller, address onBehalfOf, uint256 amount, uint256 index) with (env e2) {
            require index == gRNI();
        }
        preserved burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) with (env e3) {
            require index == gRNI();
        }
    }
*/  

/*
  --------------------------------------------------------------------------------------
  | NOTE: this rule is timed out, hence removed from current CI.                       |
  | Currently we are waiting for dev to fix this issue. (the rule run fine using CVL1) |
  -------------------------------------------------------------------------------------

  Transfer is additive, can performed either all at once or gradually
  transfer(from,to,x); transfer(from,to,y) ~ transfer(from,to,x+y) at the same initial state
*/
rule additiveTransfer(address from1, address from2, address to1, address to2, uint256 x, uint256 y)
{
    env e1;
    env e2;
    uint256 indexRay = gRNI();
    require (from1 != from2 && to1 != to2 && from1 != to2 && from2 != to1 && 
             (from1 == to1 <=> from2 == to2) &&
             balanceOf(from1) == balanceOf(from2) && balanceOf(to1) == balanceOf(to2));
    
    require e1.msg.sender == from1;
    require e2.msg.sender == from2;
    transfer(e1, to1, x);
    transfer(e1, to1, y);
    uint256 balanceFromScenario1 = balanceOf(from1);
    uint256 balanceToScenario1 = balanceOf(to1);
    
    transfer(e2, to2, require_uint256(x+y));
    
    uint256 balanceFromScenario2 = balanceOf(from2);
    uint256 balanceToScenario2 = balanceOf(to2);
    
    assert 	bounded_error_eq(balanceFromScenario1, balanceFromScenario2, 3)  &&
        bounded_error_eq(balanceToScenario1, balanceToScenario2, 3), "transfer is not additive";
}


rule additiveBurn(address user1, address user2, address to1, address to2, uint256 x, uint256 y)
{
    env e;
    uint256 indexRay = gRNI();
    require (user1 != user2 && to1 != to2 && user1 != to2 && user2 != to1 &&
             (user1 == to1 <=> user2 == to2) &&
             balanceOf(user1) == balanceOf(user2) && balanceOf(to1) == balanceOf(to2));
    require user1 != currentContract && user2 != currentContract;
    
    burn(e, user1, to1, x, indexRay);
    burn(e, user1, to1, y, indexRay);
    uint256 balanceUserScenario1 = balanceOf(user1);
    
    burn(e, user2, to2, require_uint256(x+y), indexRay);
    uint256 balanceUserScenario2 = balanceOf(user2);

    assert bounded_error_eq(balanceUserScenario1, balanceUserScenario2, 3), "burn is not additive";
}

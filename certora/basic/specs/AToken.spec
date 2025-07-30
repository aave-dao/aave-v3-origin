
// ****
// We check for the following values of index: RAY(), 2*RAY(), 3*RAY(), ... , 255*RAY(),
// except for totalSupplyEqualsSumAllBalance and additiveTransfer where we check only for index==7*RAY().
// ****
using SimpleERC20 as _underlyingAsset;

methods {
  function nonces(address) external returns (uint256) envfree;
  function allowance(address, address) external returns (uint256) envfree;
  function _.handleAction(address, uint256, uint256) external => NONDET;
  function _.getReserveNormalizedIncome(address u) external => INDEX_ray expect uint256 ALL;
  function balanceOf(address) external returns (uint256) envfree;
  function additionalData(address) external returns uint128 envfree;
  function _.finalizeTransfer(address, address, address, uint256, uint256, uint256) external => NONDET;

  function scaledTotalSupply() external returns (uint256) envfree;
  function scaledBalanceOf(address) external returns (uint256) envfree;
  function scaledBalance_to_balance(uint256) external returns (uint256) envfree;
}

definition ray() returns uint = 10^27;
definition bound() returns mathint = INDEX;

// ****
// Due to rayDiv and RayMulCeil/Floor Rounding - balance could increase by INDEX + 1.
// ****
definition bounded_error_eq(uint x, uint y, uint scale) returns bool =
  to_mathint(x) <= to_mathint(y) + (bound() * scale)
  &&
  to_mathint(y) <= to_mathint(x) + (bound() * scale);

persistent ghost sumAllScaledBalance() returns mathint {
  init_state axiom sumAllScaledBalance() == 0;
}

// summerization for scaledBlanaceOf -> regularBalanceOf + 0.5 (canceling the rayMul)
persistent ghost uint256 INDEX_ray {
  axiom INDEX_ray == INDEX * ray();
}
persistent ghost uint8 INDEX {
  //  axiom 1==1;
  axiom INDEX==7;
}


hook Sstore _userState[KEY address a].balance uint120 balance (uint120 old_balance) {
  havoc sumAllScaledBalance assuming sumAllScaledBalance@new() == sumAllScaledBalance@old() + balance - old_balance;
}

invariant totalSupplyEqualsSumAllBalance(env e)
  totalSupply(e) == scaledBalance_to_balance(require_uint256(sumAllScaledBalance()))
  {
    preserved {
      require (INDEX==7); // Otherwise we get a timeout
    }
  }

// Rule to verify that permit sets the allowance correctly.
rule permitIntegrity(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) {
  env e;
  uint256 nonceBefore = nonces(owner);
  permit(e, owner, spender, value, deadline, v, r, s);
  assert allowance(owner, spender) == value;
  assert to_mathint(nonces(owner)) == nonceBefore + 1;
}

// can't mint zero Tokens
rule mintArgsPositive(address user, uint256 amount, uint256 index) {
  env e;
  address caller;
  mint@withrevert(e, caller, user, amount, index);
  assert amount == 0 => lastReverted;
}

// ****
// Check that each possible operation changes the balance of at most two users
// ****
rule balanceOfChange(address a, address b, address c, method f )
  filtered { f ->  !f.isView }
{
  env e;
  require a!=b && a!=c && b!=c;
  uint256 balanceABefore = balanceOf(a);
  uint256 balanceBBefore = balanceOf(b);
  uint256 balanceCBefore = balanceOf(c);

  calldataarg arg;
  f(e, arg);

  uint256 balanceAAfter = balanceOf(a);
  uint256 balanceBAfter = balanceOf(b);
  uint256 balanceCAfter = balanceOf(c);

  assert ( balanceABefore == balanceAAfter || balanceBBefore == balanceBAfter || balanceCBefore == balanceCAfter);
}

// ****
// Mint to user u amount of x tokens, increases his balanceOf the underlying asset by x and
// AToken total suplly should increase.
// ****
rule integrityMint(address usr, uint256 scaled_amount) {
  env e;

  uint256 underlyingBalanceBefore = balanceOf(usr);
  uint256 atokenBlanceBefore = scaledBalanceOf(usr);
  uint256 totalATokenSupplyBefore = scaledTotalSupply();

  address caller; uint256 index; // These 2 params are only for emits - hance we don't care about them.
  mint(e,caller,usr,scaled_amount,index);

  uint256 underlyingBalanceAfter = balanceOf(usr);
  uint256 atokenBlanceAfter = scaledBalanceOf(usr);
  uint256 totalATokenSupplyAfter = scaledTotalSupply();

  assert atokenBlanceAfter - atokenBlanceBefore == totalATokenSupplyAfter - totalATokenSupplyBefore;
  assert totalATokenSupplyAfter > totalATokenSupplyBefore;
  assert underlyingBalanceAfter == underlyingBalanceBefore + scaled_amount*INDEX;
}


// ****
// Mint is additive, can performed either all at once or gradually
// mint(u,x); mint(u,y) ~ mint(u,x+y) at the same initial state
// ****
rule additiveMint(address usr1, address usr2, uint256 x, uint256 y) {
  env e;
  require(balanceOf(usr1) == balanceOf(usr2) && usr1 != usr2);
  
  address caller; uint256 ind; // These 2 params are only for emits - hance we don't care about them.
  mint(e, caller, usr1, x, ind);
  mint(e, caller, usr1, y, ind);
  uint256 balanceScenario1 = balanceOf(usr1);
  mint(e, caller, usr2, assert_uint256(x+y) ,ind);

  uint256 balanceScenario2 = balanceOf(usr2);
  assert bounded_error_eq(balanceScenario1, balanceScenario2, 3), "mint is not additive";
}



// ****
// transfers amount from _userState[from].balance to _userState[to].balance
// while balance of returns _userState[account].balance normalized by gNRI();
// transfer is incentivizedERC20
// ****
rule integrityTransfer(address from, address to, uint256 amount) {
  env e;
  require e.msg.sender == from;
  address other; // for any address including from, to, currentContract the underlying asset balance should stay the same

  uint256 balanceBeforeFrom = balanceOf(from);
  uint256 balanceBeforeTo = balanceOf(to);
  uint256 underlyingBeforeOther = _underlyingAsset.balanceOf(e, other);

  transfer(e, to, amount);

  uint256 balanceAfterFrom = balanceOf(from);
  uint256 balanceAfterTo = balanceOf(to);
  uint256 underlyingAfterOther =  _underlyingAsset.balanceOf(e, other);

  assert underlyingAfterOther == underlyingBeforeOther, "unexpected change in underlying asserts";

  if (from != to) {
    assert bounded_error_eq(balanceAfterFrom, assert_uint256(balanceBeforeFrom-amount), 1) &&
      bounded_error_eq(balanceAfterTo, assert_uint256(balanceBeforeTo+amount), 1), "unexpected balance of from/to, when from!=to";
  } else {
    assert balanceAfterFrom == balanceAfterTo , "unexpected balance of from/to, when from==to";
  }
}


// ****
// Transfer is additive, can performed either all at once or gradually
// transfer(from,to,x); transfer(from,to,y) ~ transfer(from,to,x+y) at the same initial state
// ****
rule additiveTransfer(address from1, address from2, address to1, address to2, uint256 x, uint256 y) {
  env e1;
  env e2;
  require (INDEX==7); // Otherwise we get a timeout
  require (
    from1 != from2 && to1 != to2 && from1 != to2 && from2 != to1 &&
    (from1 == to1 <=> from2 == to2) &&
    balanceOf(from1) == balanceOf(from2) && balanceOf(to1) == balanceOf(to2)
  );

  require e1.msg.sender == from1;
  require e2.msg.sender == from2;
  transfer(e1, to1, x);
  transfer(e1, to1, y);
  uint256 balanceFromScenario1 = balanceOf(from1);
  uint256 balanceToScenario1 = balanceOf(to1);

  transfer(e2, to2, assert_uint256(x+y));

  uint256 balanceFromScenario2 = balanceOf(from2);
  uint256 balanceToScenario2 = balanceOf(to2);

  assert
    bounded_error_eq(balanceFromScenario1, balanceFromScenario2, 3)  &&
    bounded_error_eq(balanceToScenario1, balanceToScenario2, 3), "transfer is not additive";
}


// ****
// Burn scaled amount of Atoken from 'user' and transfers amount of the underlying asset to 'to'.
// ****
rule integrityBurn(address user, address to, uint256 amount, uint256 scaledAmount) {
  env e;

  require user != currentContract;
  uint256 balanceBeforeUser = balanceOf(user);
  uint256 balanceBeforeTo = balanceOf(to);
  uint256 underlyingBeforeTo =  _underlyingAsset.balanceOf(e, to);
  uint256 underlyingBeforeUser =  _underlyingAsset.balanceOf(e, user);
  uint256 underlyingBeforeSystem =  _underlyingAsset.balanceOf(e, currentContract);
  uint256 totalSupplyBefore = totalSupply(e);

  uint256 ind;
  burn(e, user, to, amount, scaledAmount, ind);

  uint256 balanceAfterUser = balanceOf(user);
  uint256 balanceAfterTo = balanceOf(to);
  uint256 underlyingAfterTo =  _underlyingAsset.balanceOf(e, to);
  uint256 underlyingAfterUser =  _underlyingAsset.balanceOf(e, user);
  uint256 underlyingAfterSystem =  _underlyingAsset.balanceOf(e, currentContract);
  uint256 totalSupplyAfter = totalSupply(e);

  if (user != to) {
    assert balanceAfterTo == balanceBeforeTo && // balanceOf To should not change
      underlyingBeforeUser== underlyingAfterUser;
  }

  if (to != currentContract) {
    assert bounded_error_eq(underlyingAfterSystem, assert_uint256(underlyingBeforeSystem-amount), 1) // system transfer underlying_asset
      && 
      bounded_error_eq(underlyingAfterTo, assert_uint256(underlyingBeforeTo+amount), 1) , "integrity break on to!=currentContract";
  } else {
    assert underlyingAfterSystem == underlyingBeforeSystem, "integrity break on to==currentContract";
  }

  assert bounded_error_eq(totalSupplyAfter, assert_uint256(totalSupplyBefore-scaledAmount*INDEX), 1),
    "total supply integrity"; // total supply reduced
  assert bounded_error_eq(balanceAfterUser, assert_uint256(balanceBeforeUser-scaledAmount*INDEX), 1),
    "integrity break";  // user burns ATokens to recieve underlying
}


// ****
// Burn is additive, can performed either all at once or gradually
// burn(from,to,x,index); burn(from,to,y,index) ~ burn(from,to,x+y,index) at the same initial state
// ****
rule additiveBurn(address user1, address user2, address to1, address to2, uint256 x, uint256 y) {
  env e;
  require (
    user1 != user2 && to1 != to2 && user1 != to2 && user2 != to1 &&
    (user1 == to1 <=> user2 == to2) &&
    balanceOf(user1) == balanceOf(user2) && balanceOf(to1) == balanceOf(to2)
  );
  require user1 != currentContract && user2 != currentContract;

  uint256 amount1; uint256 amount2; uint256 amount3; uint256 ind; // we dont care aboute these values
  burn(e, user1, to1, amount1, x, ind);
  burn(e, user1, to1, amount2, y, ind);
  uint256 balanceUserScenario1 = balanceOf(user1);

  burn(e, user2, to2, amount3, assert_uint256(x+y), ind);
  uint256 balanceUserScenario2 = balanceOf(user2);

  assert bounded_error_eq(balanceUserScenario1, balanceUserScenario2, 3), "burn is not additive";
}


// ****
// Burning one user atokens should have no effect on other users that are not involved in the action.
// ****
rule burnNoChangeToOther(address user, address recieverOfUnderlying, uint256 amount,
                         uint256 scaledAmount, uint256 index, address other) {
  require other != user && other != recieverOfUnderlying;
  env e;
  uint256 otherDataBefore = additionalData(other);
  uint256 otherBalanceBefore = balanceOf(other);

  burn(e, user, recieverOfUnderlying, amount, scaledAmount, index);

  uint256 otherDataAfter = additionalData(other);
  uint256 otherBalanceAfter = balanceOf(other);

  assert otherDataBefore == otherDataAfter &&
    otherBalanceBefore == otherBalanceAfter;
}


// ****
// Minting ATokens for a user should have no effect on other users that are not involved in the action.
// ****
rule mintNoChangeToOther(address user, uint256 scaledAmount, uint256 index, address other) {
  require other != user;

  env e;
  uint128 otherDataBefore = additionalData(other);
  uint256 otherBalanceBefore = balanceOf(other);
  address caller;
  mint(e, caller, user, scaledAmount, index);

  uint128 otherDataAfter = additionalData(other);
  uint256 otherBalanceAfter = balanceOf(other);

  assert otherBalanceBefore == otherBalanceAfter && otherDataBefore == otherDataAfter;
}


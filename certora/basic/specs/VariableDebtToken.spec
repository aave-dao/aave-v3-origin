// ****
// We check for the following values of index: RAY(), 2*RAY(), 3*RAY(), ... , 255*RAY(),
// except for totalSupplyEqualsSumAllBalance where we check only for index==7*RAY().
// ****

methods {
  // summarization for elimination the raymul operation in balance of and totalSupply.
  function _.getReserveNormalizedVariableDebt(address asset) external => INDEX_ray expect uint256 ALL;
  function _.handleAction(address, uint256, uint256) external => NONDET;
  function scaledBalanceOfToBalanceOf(uint256) external returns (uint256) envfree;
  function balanceOf(address) external returns (uint256) envfree;
}

definition ray() returns uint = 10^27;
definition bound() returns mathint = INDEX;

// *****
// Due to rayDiv and RayMul Rounding (+ 0.5) - blance could increase by (gRNI() / Ray() + 1) / 2.
// *****
definition bounded_error_eq(mathint x, mathint y, mathint scale) returns bool =
  x <= y + (bound() * scale)
  &&
  y <= x + (bound() * scale);

// summerization for scaledBlanaceOf -> regularBalanceOf + 0.5 (canceling the rayMul)
persistent ghost uint256 INDEX_ray {
  axiom INDEX_ray == INDEX * ray();
}
persistent ghost uint8 INDEX {
  //  axiom 1==1;
  axiom INDEX==7;
}



definition disAllowedFunctions(method f) returns bool =
  f.selector == sig:transfer(address, uint256).selector ||
  f.selector == sig:allowance(address, address).selector ||
  f.selector == sig:approve(address, uint256).selector ||
  f.selector == sig:transferFrom(address, address, uint256).selector ||
  f.selector == sig:increaseAllowance(address, uint256).selector ||
  f.selector == sig:decreaseAllowance(address, uint256).selector;

ghost sumAllBalance() returns mathint {
  init_state axiom sumAllBalance() == 0;
}
hook Sstore _userState[KEY address a].balance uint120 balance (uint120 old_balance) {
  havoc sumAllBalance assuming sumAllBalance@new() == sumAllBalance@old() + balance - old_balance;
}

invariant totalSupplyEqualsSumAllBalance(env e)
  totalSupply(e) == scaledBalanceOfToBalanceOf(require_uint256(sumAllBalance()))
  filtered { f -> !f.isView && !disAllowedFunctions(f) }
  {
    preserved {
      require (INDEX==7); // Otherwise we get a timeout
    }
  }

// Only the pool with burn or mint operation can change the total supply. (assuming the getReserveNormalizedVariableDebt is not changed)
rule whoChangeTotalSupply(method f)
  filtered { f ->  !f.isView && !disAllowedFunctions(f) }
{
  env e;
  uint256 oldTotalSupply = totalSupply(e);
  calldataarg args;
  f(e, args);
  uint256 newTotalSupply = totalSupply(e);
  assert oldTotalSupply != newTotalSupply =>
    (e.msg.sender == POOL(e) &&
    (f.selector == sig:burn(address,uint256,uint256).selector ||
    f.selector == sig:mint(address,address,uint256,uint256,uint256).selector));
}

// *****
// Each operation of Variable Debt Token can change at most one user's balance.
// *****
rule balanceOfChange(address a, address b, method f)
  filtered { f ->  !f.isView && !disAllowedFunctions(f) }
{
	env e;
	require a != b;
	uint256 balanceABefore = balanceOf(a);
	uint256 balanceBBefore = balanceOf(b);

	calldataarg arg;
  f(e, arg);

	uint256 balanceAAfter = balanceOf(a);
	uint256 balanceBAfter = balanceOf(b);

	assert (balanceABefore == balanceAAfter || balanceBBefore == balanceBAfter);
}


// only delegationWithSig operation can change the nonce.
rule nonceChangePermits(method f)
  filtered { f ->  !f.isView && !disAllowedFunctions(f) }
{
  env e;
  address user;
  uint256 oldNonce = nonces(e, user);
  calldataarg args;
  f(e, args);
  uint256 newNonce = nonces(e, user);
  assert oldNonce != newNonce => f.selector == sig:delegationWithSig(address, address, uint256, uint256, uint8, bytes32, bytes32).selector;
}

// minting and then buring Variable Debt Token should have no effect on the users balance
rule inverseMintBurn(address a, address delegatedUser, uint256 amount, uint256 scaledAmount, uint256 index) {
  env e;
  uint256 balancebefore = balanceOf(a);
  mint(e, delegatedUser, a, amount, scaledAmount, index);
  burn(e, a, scaledAmount, index);
  uint256 balanceAfter = balanceOf(a);
  assert balancebefore == balanceAfter, "burn is not the inverse of mint";
}

rule integrityDelegationWithSig(address delegator, address delegatee, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) {
  env e;
  uint256 oldNonce = nonces(e, delegator);
  delegationWithSig(e, delegator, delegatee, value, deadline, v, r, s);
  assert to_mathint(nonces(e, delegator)) == oldNonce + 1
    &&
    borrowAllowance(e, delegator, delegatee) == value;
}

// *****
// Burning user u amount of amount tokens, decreases his balanceOf the user by amount.
// (balance is decreased by amount and not scaled amount because of the summarization to one ray)
// *****
rule integrityOfBurn(address u, uint256 amountScaled) {
  env e;
  uint256 balanceBeforeUser = balanceOf(u);
  uint256 totalSupplyBefore = totalSupply(e);

  uint256 ind; // We dont care for this value
  burn(e, u, amountScaled, ind);

  uint256 balanceAfterUser = balanceOf(u);
  uint256 totalSupplyAfter = totalSupply(e);

  assert bounded_error_eq(totalSupplyAfter, totalSupplyBefore - amountScaled*INDEX, 1), "total supply integrity"; // total supply reduced
  assert bounded_error_eq(balanceAfterUser, balanceBeforeUser - amountScaled*INDEX, 1), "integrity break";  // user burns ATokens to recieve underlying
}

// *****
// Burn is additive, can performed either all at once or gradually
// burn(from,to,x,index); burn(from,to,y,index) ~ burn(from,to,x+y,index) at the same initial state
// *****
rule additiveBurn(address user1, address user2, uint256 x, uint256 y) {
  env e;
  require (user1 != user2  && balanceOf(user1) == balanceOf(user2));
  require user1 != currentContract && user2 != currentContract;

  uint256 ind; // We dont care for this value
  burn(e, user1, x, ind);
  burn(e, user1, y, ind);
  uint256 balanceScenario1 = balanceOf(user1);
  
  burn(e, user2, assert_uint256(x+y), ind);
  uint256 balanceScenario2 = balanceOf(user2);

  assert bounded_error_eq(balanceScenario1, balanceScenario2, 3), "burn is not additive";
}


// *****
// Mint is additive, can performed either all at once or gradually
// mint(from,to,x,index); mint(from,to,y,index) ~ mint(from,to,x+y,index) at the same initial state
// *****
rule additiveMint(address user1, address user2, address user3, uint256 x, uint256 y) {
  env e;
  require (user1 != user2  && balanceOf(user1) == balanceOf(user2));

  uint256 amount1; uint256 amount2; uint256 amount3; //these values have no effects on the minting amount
  uint256 ind; // We dont care for this value
  mint(e, user3, user1, amount1, x, ind);
  mint(e, user3, user1, amount2, y, ind);
  uint256 balanceScenario1 = balanceOf(user1);
  
  mint(e, user3, user2, amount3, assert_uint256(x+y), ind);
  uint256 balanceScenario2 = balanceOf(user2);
  
  assert bounded_error_eq(balanceScenario1, balanceScenario2, 3), "burn is not additive";
}

// *****
// Mint to user u amount of x tokens, increases his balanceOf the user by x.
// (balance is increased by x and not scaled x because of the summarization to one ray)
// *****
rule integrityMint(address a, uint256 x) {
  env e;
  address delegatedUser;
  uint256 underlyingBalanceBefore = balanceOf(a);
  uint256 atokenBlanceBefore = scaledBalanceOf(e, a);
  uint256 totalATokenSupplyBefore = scaledTotalSupply(e);

  uint256 ind; uint256 amount; //this value has no effects on the minting amount
  mint(e, delegatedUser, a, amount, x, ind);
  
  uint256 underlyingBalanceAfter = balanceOf(a);
  uint256 atokenBlanceAfter = scaledBalanceOf(e, a);
  uint256 totalATokenSupplyAfter = scaledTotalSupply(e);

  assert atokenBlanceAfter - atokenBlanceBefore == totalATokenSupplyAfter - totalATokenSupplyBefore;
  assert totalATokenSupplyAfter > totalATokenSupplyBefore;
  assert bounded_error_eq(underlyingBalanceAfter, underlyingBalanceBefore+x*INDEX, 1);
}

// Buring zero amount of tokens should have no effect.
rule burnZeroDoesntChangeBalance(address u, uint256 index) {
  env e;
  uint256 balanceBefore = balanceOf(u);
  burn@withrevert(e, u, 0, index);
  uint256 balanceAfter = balanceOf(u);
  assert balanceBefore == balanceAfter;
}

// *****
// Burning one user atokens should have no effect on other users that are not involved in the action.
// *****
rule burnNoChangeToOther(address user, uint256 amount, uint256 index, address other) {
  require other != user;
  uint256 otherBalanceBefore = balanceOf(other);

  env e;
  burn(e, user, amount, index);

  uint256 otherBalanceAfter = balanceOf(other);
  assert otherBalanceBefore == otherBalanceAfter;
}

// *****
// Minting ATokens for a user should have no effect on other users that are not involved in the action.
// *****
rule mintNoChangeToOther(address user, address onBehalfOf, uint256 amount, uint256 scaledAmount, uint256 index, address other) {
  require other != user && other != onBehalfOf;

  env e;
  uint256 userBalanceBefore = balanceOf(user);
  uint256 otherBalanceBefore = balanceOf(other);

  mint(e, user, onBehalfOf, amount, scaledAmount, index);

  uint256 userBalanceAfter = balanceOf(user);
  uint256 otherBalanceAfter = balanceOf(other);
  
  if (user != onBehalfOf)
    assert userBalanceBefore == userBalanceAfter ;

  assert otherBalanceBefore == otherBalanceAfter ;
}

// *****
// Ensuring that the defined disallowed functions revert in any case.
// *****
rule disallowedFunctionalities(method f)
  filtered { f -> disAllowedFunctions(f) }
{
  env e; calldataarg args;
  f@withrevert(e, args);
  assert lastReverted;
}


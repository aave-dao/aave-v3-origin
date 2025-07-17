// decide whether we want to summarize here for VariableDebtToken and StableDebtToken too, as interfaces are similar and so are some of the implementations.

import "ERC20/erc20cvlForAave.spec";
import "./rayMulDiv-CVL.spec";

using PoolInstanceHarness as poolInstance;

methods {
  /* AToken methods */
  // no side effects:
  function _.scaledTotalSupply() external => scaledTotalSupplyCVL(calledContract) expect uint256;
  function _.scaledBalanceOf(address user) external => scaledBalanceOfCVL(calledContract, user) expect uint256;
  function _.balanceOf(address user) external with (env e) => aTokenBalanceOfCVL(calledContract, user, e) expect uint256;
  function _.totalSupply() external with (env e) => aTokenTotalSupplyCVL(calledContract, e) expect uint256;

  // addresses
  function _.POOL() external => thePool expect address;
  function _.RESERVE_TREASURY_ADDRESS() external => theTreasury expect address;

  // StableDebt only:
  function _.getSupplyData() external => NONDET; // expect (uint256, uint256, uint256, uint40);

  // with side effects:
  function _.transfer(address to, uint256 amount) external with (env e)
    => aTokenTransferCVL(calledContract, to, amount, e) expect bool;
  function _.transfer(address to, uint256 amount) internal with (env e)
    => aTokenTransferCVL(calledContract, to, amount, e) expect bool;
  function _.transferFrom(address from, address to, uint256 amount) external with (env e)
    => transferFromCVL(calledContract, from, to, amount, e) expect bool;

  // matches AToken only
  function _.mint(address caller, address onBehalfOf, uint256 scaledAmount, uint256 index) external
    => aTokenMintCVL(calledContract, caller, onBehalfOf, scaledAmount, index) expect bool;

  // matches VariableDebtToken only
  function _.mint(address user, address onBehalfOf, uint256 amount, uint256 scaledAmount, uint256 index) external
    => variableDebtMintCVL(calledContract, user, onBehalfOf, amount, scaledAmount, index) expect uint;

  function _.mintToTreasury(uint256 scaledAmount, uint256 index) external
    => aTokenMintToTreasuryCVL(calledContract, scaledAmount, index) expect void;

  // matches AToken only
  function _.burn(address from, address receiverOfUnderlying, uint256 amount, uint256 scaledAmount, uint256 index) external
    => aTokenBurnCVL(calledContract, from, receiverOfUnderlying, amount, scaledAmount, index) expect bool;
  
  // matches VariableDebtToken only
  function _.burn(address from, uint256 scaledAmount, uint256 index) external =>
    variableDebtBurnCVL(calledContract, from, scaledAmount, index) expect (bool,uint256);

  // matches StableDebtToken only: nissan: should be removed
  function _.burn(address from, uint256 amount) external
    => stableDebtBurnCVL(calledContract, from, amount) expect (uint256, uint256);

  function _.transferUnderlyingTo(address target, uint256 amount) external
    => aTokenTransferUnderlyingToCVL(calledContract, target, amount) expect void;

  function _.transferOnLiquidation(address from, address to, uint256 amount, uint256 scaledAmount, uint256 index) external
    => aTokenTransferOnLiquidationCVL(calledContract, from, to, amount, scaledAmount, index) expect void;

  function _.handleRepayment(address user, address onBehalfOf, uint256 amount) external
    => aTokenHandleRepaymentCVL(calledContract, user, onBehalfOf, amount) expect void;

  function _.rescueTokens(address token, address to, uint256 amount) external with (env e)
    => aTokenRescueTokensCVL(calledContract, token, to, amount, e) expect void;
  

  

  // Side effects we don't care about
  function _._setName(string memory) internal => NONDET;
  function _._setSymbol(string memory) internal => NONDET;
  // Getters with loops
  // Pending Johannes' PR?
  // function _.name() internal => nameCVL expect string;
  // function _.symbol() internal => symbolCVL expect string;
}

// Pending Johannes' PR?
// ghost string nameCVL;
// ghost string symbolCVL;

// Pool address - same for all aTokens
// ASSUMES WE HAVE THE POOL IN THE SCENE
persistent ghost address thePool {
    axiom thePool == poolInstance;
}

// Treasury address - same for all aTokens
persistent ghost address theTreasury {
  init_state axiom theTreasury == 0;
}

/// aToken => scaledTotalSupply
// this is just totalSupplyByToken

/// aToken => account => scaledBalance
// this is just balanceByToken

/// aToken => underlying
/// We'd like to prove that aTokens never map to aTokens, e.g.
/// forall address aToken. aToken == 0 || aTokenToUnderlying[aToken] == 0 || aTokenToUnderlying[aTokenToUnderlying[aToken]] == 0
persistent ghost mapping(address => address) aTokenToUnderlying {
    init_state axiom forall address a. aTokenToUnderlying[a] == 0;
}

// xxx can we use a sort instead?
definition VanillaERC20_token() returns mathint = 0;
definition AToken_token() returns mathint = 1;
definition VariableDebtToken_token() returns mathint = 2;

persistent ghost mapping (address => mathint) tokenToSort {
    axiom forall address a. 0 <= tokenToSort[a] && tokenToSort[a] <= 2; 
}

function scaledTotalSupplyCVL(address token) returns uint256 {
    return require_uint256(totalSupplyByToken[token]);
}

function scaledBalanceOfCVL(address token, address user) returns uint256 {
  //    return require_uint256(balanceByToken[token][user]);
    return balanceByToken[token][user];
}

function indexForToken(address token, env e) returns uint256 {
  uint index;
  mathint tokenSort = tokenToSort[token];
  if (tokenSort == AToken_token()) {
    index = poolInstance.getReserveNormalizedIncome(e, aTokenToUnderlying[token]);
  } else if (tokenSort == VariableDebtToken_token()) {
    index = poolInstance.getReserveNormalizedVariableDebt(e, aTokenToUnderlying[token]);
  } else {
    index = 0; 
    assert false, "unsupported token type";
  }
  return index;
}

// todo: adjust for stable debt token
function aTokenBalanceOfCVL(address token, address user, env e) returns uint256 {
    uint storedBalance = balanceOfCVL(token, user);
    if (aTokenToUnderlying[token] == 0) {
        // not a properly initialized aToken, return the regular ERC20 balance
        return storedBalance;
    }
    // hopefully this is the only place we actually call the pool
    uint index = indexForToken(token, e);
    uint ret;
    if (tokenToSort[token]==AToken_token())
      ret = rayMulFloorCVL(storedBalance, index);
    else // must be VariableDebtToken
      ret = rayMulCeilCVL(storedBalance, index);
    return ret;
}

persistent ghost bool PERFORM_INTERNAL_CHECK {
  axiom PERFORM_INTERNAL_CHECK == true;
}

// todo: adjust for stableDebtToken which has a completely different implementation
// and make sure to handle for variableDebtToken (same implementation based on underlying index) 
function aTokenTotalSupplyCVL(address token, env e) returns uint256 {
  uint storedTotalSupply = totalSupplyCVL(token);
  if (aTokenToUnderlying[token] == 0) {
    if (PERFORM_INTERNAL_CHECK)
      assert false; //  If we reach here - we have a bug in the spec !
    // not a properly initialized aToken, return the regular ERC20 totalSupply
    return storedTotalSupply;
  }
  // hopefully this is the only place we actually call the pool
  uint index = indexForToken(token, e);
  uint ret;
  if (tokenToSort[token]==AToken_token())
    ret = rayMulFloorCVL(storedTotalSupply, index);
  else // must be VariableDebtToken
    ret = rayMulCeilCVL(storedTotalSupply, index);
  return ret;
}

// xxx for VariableDebtToken and StableDebtToken, all transfer functions are disabled
// so need to have reverting summaries for this
function aTokenTransferCVL(address token, address to, uint256 amount, env e) returns bool {
    aTokenTransferCVLInternal(token, e.msg.sender, to, amount, e);
    return true;
}

function aTokenTransferCVLInternal(address token, address from, address to, uint256 amount, env e) {
  address underlying = aTokenToUnderlying[token];
  if (underlying == 0) {
    //    assert false;  // not a properly initialized aToken
    transferCVL(token, from, to, amount); // not a properly initialized aToken
  } else {
    // based on AToken.sol
    uint index = poolInstance.getReserveNormalizedIncome(e, underlying);
    aTokenTransferCVLInternal_index(token, from, to, amount, index);
  }
}

function aTokenTransferCVLInternal_SCALED(address token, address from, address to, uint256 scaledAmount /*nissan*/, uint256 index) {
  address underlying = aTokenToUnderlying[token];
  if (underlying == 0) {
    assert false;   // not a properly initialized aToken !!
  } else {
    // based on AToken.sol
    //    uint scaledAmount = rayDivCeilCVL(amount, index); 
    transferCVL(token, from, to, scaledAmount);
    // no call to POOL.finalizeTransfer.
  }
}

function aTokenTransferCVLInternal_index(address token, address from, address to, uint256 amount, uint256 index) {
  address underlying = aTokenToUnderlying[token];
  if (underlying == 0) {
    assert false;   // not a properly initialized aToken !!
  } else {
    // based on AToken.sol
    uint scaledAmount = rayDivCeilCVL(amount, index); 
    transferCVL(token, from, to, scaledAmount);
    // no call to POOL.finalizeTransfer.
  }
}

function transferFromCVL(address token, address from, address to, uint256 amount, env e) returns bool {
  mathint tokenSort = tokenToSort[token];
  if (tokenSort == AToken_token())
    return aTokenTransferFromCVL(token, from, to, amount, e);
  else if (tokenSort == VanillaERC20_token())
    return vanillaERC20_transferFromCVL(token, to, from, to, amount);
  else {
    assert false; //we can't reach here !
    return false;
  }
}


function aTokenTransferFromCVL(address token, address from, address to, uint256 amount, env e) returns bool {
  address spender = e.msg.sender;
  // copied from erc20cvl.spec:
  
  uint256 index = indexForToken(token,e);

  //  uint256 corrected_amount = rayMulFloorCVL(rayDivCeilCVL(amount, index), index);
  uint256 scaledBalOf_from = balanceByToken[token][from];
  uint256 corrected_amount =
    require_uint256(
      rayMulFloorCVL(scaledBalOf_from,index) -
      rayMulFloorCVL(require_uint256(scaledBalOf_from - rayDivCeilCVL(amount, index)), index)
    );
    
  if (allowanceByToken[token][from][spender] < amount) return false; // The actual Solidity code reverts.

  if (allowanceByToken[token][from][spender] >= corrected_amount)
    allowanceByToken[token][from][spender] = assert_uint256(allowanceByToken[token][from][spender] - corrected_amount);
  else
    allowanceByToken[token][from][spender] = 0;
    
  // custom part:
  aTokenTransferCVLInternal(token, from, to, amount, e);
  return true;
}

// mint in AToken: scaled erc20 minut + update user index.
// xxx mint in VariableDebtToken: decrease borrow allowance + same as AToken
function aTokenMintCVL(address token, address from, address to, uint scaledAmount, uint index) returns (bool) {
  assert tokenToSort[token]==AToken_token();

  bool ret = balanceByToken[token][to] == 0;

  balanceByToken[token][to] = require_uint256(balanceByToken[token][to] + scaledAmount);
  totalSupplyByToken[token] = require_uint256(totalSupplyByToken[token] + scaledAmount);

  return ret;
}

// mint in AToken: scaled erc20 minut + update user index.
// xxx mint in VariableDebtToken: decrease borrow allowance + same as AToken
function variableDebtMintCVL(address token, address from, address to, uint amount, uint scaledAmount, uint index) returns (uint) {
  assert tokenToSort[token]==VariableDebtToken_token();

  balanceByToken[token][to] = require_uint256(balanceByToken[token][to] + scaledAmount);
  totalSupplyByToken[token] = require_uint256(totalSupplyByToken[token] + scaledAmount);

  return totalSupplyByToken[token];
}

// burn in AToken: scaled erc20 burn + update user index + in the underlying, transfer amount to the receiver
function aTokenBurnCVL(address token, address from, address receiverOfUnderlying, uint amount, uint scaledAmount, uint index) returns bool {
  assert tokenToSort[token]==AToken_token();

  bool ret = (scaledAmount==balanceByToken[token][from]);
  
  balanceByToken[token][from] = require_uint256(balanceByToken[token][from] - scaledAmount);  
  totalSupplyByToken[token] = require_uint256(totalSupplyByToken[token] - scaledAmount);
  if (receiverOfUnderlying != token) {
    transferCVL(aTokenToUnderlying[token], token, receiverOfUnderlying, amount);
  }

  return ret;
}

function aTokenTransferUnderlyingToCVL(address token, address target, uint amount) {
    transferCVL(aTokenToUnderlying[token], token, target, amount);
}

function aTokenMintToTreasuryCVL(address token, uint scaledAmount, uint index) {
  // based on AToken.sol
  if (scaledAmount == 0) {
    return;
  }

  aTokenMintCVL(token, thePool, theTreasury , scaledAmount, index);
}

function aTokenTransferOnLiquidationCVL(address token, address from, address to, uint amount, uint scaledAmount, uint index) {
  aTokenTransferCVLInternal_SCALED(token, from, to, scaledAmount, index);
}

function aTokenHandleRepaymentCVL(address token, address user, address onBehalfOf, uint amount) {
    // In AToken.sol, does nothing.
}

function aTokenRescueTokensCVL(address token, address tokenToRescue, address to, uint256 amount, env e) {
  require tokenToRescue != aTokenToUnderlying[token];
  // if the tokenToRescue is an AToken, we should make sure to call the variant that checks
  // if it's an AToken, and if it is, runs the right transfer function. This is okay since in 
  // the code of `rescueTokens`, we cast the specified token to an IERC20, so there are no
  // internal-call shenaningans
  // the env with which the transfer is called is where token (our atoken) is the sender, but I'm not sure it matters
  aTokenTransferCVLInternal(tokenToRescue, token, to, amount, e);
}

function variableDebtBurnCVL(address token, address from, uint scaledAmount, uint index) returns (bool,uint) {
  assert tokenToSort[token]==VariableDebtToken_token(); // if this fails, we have a bug in the summarizarion.

  balanceByToken[token][from] = require_uint256(balanceByToken[token][from] - scaledAmount);  
  totalSupplyByToken[token] = require_uint256(totalSupplyByToken[token] - scaledAmount);

  // based on VariableDebtToken.sol
  //  aTokenBurnCVL(token, from, 0 /* receiver of underlying */, amount, index);
  bool any_val;
  return (any_val,totalSupplyByToken[token]);
}

function stableDebtBurnCVL(address token, address from, uint amount) returns (uint, uint) {
  assert false; // We can't reach here !
  // no implementation found?
  uint nondet1;
  uint nondet2;
  return (nondet1, nondet2);
}

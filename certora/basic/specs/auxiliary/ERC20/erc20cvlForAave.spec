methods {
    // ERC20 standard
    function _.name()                                           external => NONDET; // can we use PER_CALLEE_CONSTANT?
    function _.symbol()                                         external => NONDET; // can we use PER_CALLEE_CONSTANT?
    function _.decimals()                                       external => PER_CALLEE_CONSTANT;
    // function _.totalSupply()                                    external => totalSupplyCVL(calledContract) expect uint256; // Aave specs will override
    // function _.balanceOf(address a)                             external => balanceOfCVL(calledContract, a) expect uint256; // Aave specs will override
    function _.allowance(address a, address b)                  external => allowanceCVL(calledContract, a, b) expect uint256;
    function _.approve(address a, uint256 x)                    external with (env e) => approveCVL(calledContract, e.msg.sender, a, x) expect bool;
    // function _.transfer(address a, uint256 x)                   external with (env e) => transferCVL(calledContract, e.msg.sender, a, x) expect bool; // Aave specs will override
    // function _.transferFrom(address a, address b, uint256 x)    external with (env e) => transferFromCVL(calledContract, e.msg.sender, a, b, x) expect bool; // Aave specs will override

    // increase/decrease allowance
    function _.increaseAllowance(address spender, uint256 addedValue) external with (env e) => increaseAllowanceCVL(calledContract, e.msg.sender, spender, addedValue) expect bool;
    function _.decreaseAllowance(address spender, uint256 subtractedValue) external with (env e) => decreaseAllowanceCVL(calledContract, e.msg.sender, spender, subtractedValue) expect bool;

    // Permit
    // xxx unsound
    function _.permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external => permitCVL(calledContract, owner, spender, value, deadline, v, r, s) expect void;

}


/// CVL simple implementations of IERC20:
/// token => totalSupply
persistent ghost mapping(address => uint256) totalSupplyByToken {
  init_state axiom forall address a. totalSupplyByToken[a]==0;
}

/// token => account => balance
persistent ghost mapping(address => mapping(address => uint256)) balanceByToken {
  init_state axiom forall address a. forall address b. balanceByToken[a][b]==0;
}
/// token => owner => spender => allowance
persistent ghost mapping(address => mapping(address => mapping(address => uint256))) allowanceByToken {
  init_state axiom forall address a. forall address b. forall address c. allowanceByToken[a][b][c]==0;
}

// function tokenBalanceOf(address token, address account) returns uint256 {
//     return balanceByToken[token][account];
// }

function totalSupplyCVL(address token) returns uint256 {
    return totalSupplyByToken[token];
}

function balanceOfCVL(address token, address a) returns uint256 {
    return balanceByToken[token][a];
}

function allowanceCVL(address token, address a, address b) returns uint256 {
    return allowanceByToken[token][a][b];
}

function approveCVL(address token, address approver, address spender, uint256 amount) returns bool {
    allowanceByToken[token][approver][spender] = amount;
    return true;
}

function transferFromCVL(address token, address spender, address from, address to, uint256 amount) returns bool {
    if (allowanceByToken[token][from][spender] < amount) return false;
    allowanceByToken[token][from][spender] = assert_uint256(allowanceByToken[token][from][spender] - amount);
    return transferCVL(token, from, to, amount);
}

function transferCVL(address token, address from, address to, uint256 amount) returns bool {
  //if(balanceByToken[token][from] < amount) return false;
  require balanceByToken[token][from] >= amount;
    balanceByToken[token][from] = assert_uint256(balanceByToken[token][from] - amount);
    balanceByToken[token][to] = require_uint256(balanceByToken[token][to] + amount);  // We neglect overflows.
    return true;
}

function increaseAllowanceCVL(address token, address owner, address spender, uint256 increasedAmount) returns bool {
    uint256 amt = require_uint256(allowanceCVL(token, owner, spender) + increasedAmount);
    return approveCVL(token, owner, spender, amt);
}

function decreaseAllowanceCVL(address token, address owner, address spender, uint256 decreasedAmount) returns bool {
    uint256 amt = require_uint256(allowanceCVL(token, owner, spender) - decreasedAmount);
    return approveCVL(token, owner, spender, amt);
}

function permitCVL(
    address token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) {
    // xxx not checking conditions
    approveCVL(token, owner, spender, value);
}

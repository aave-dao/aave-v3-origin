import "base_token_v3.spec";

using SymbolicLendingPoolL1 as _SymbolicLendingPoolL1;
using DummyERC20_aTokenUnderlying as Underlying;

methods {
    function ecrecoverWrapper(bytes32, uint8, bytes32, bytes32) external returns (address) envfree;
    function computeMetaDelegateHash(address delegator,  address delegatee, uint256 deadline, uint256 nonce) external returns (bytes32) envfree;
    function computeMetaDelegateByTypeHash(address delegator,  address delegatee, IBaseDelegation.GovernancePowerType delegationType, uint256 deadline, uint256 nonce) external returns (bytes32) envfree;
    //    function _nonces(address addr) external returns (uint256) envfree;
    function getNonce(address) external returns (uint256) envfree;
}


methods {
    function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256) envfree;
    //function _SymbolicLendingPoolL1.getReserveNormalizedIncome(address) external returns (uint256)  => index();
    //function _.rayMul(uint256 a,uint256 b) internal => rayMul_MI(a,b) expect uint256 ALL;
    //function _.rayDiv(uint256 a,uint256 b) internal => rayDiv_MI(a,b) expect uint256 ALL;

    //function _.getIncentivesController() external => CONSTANT;
    //function _.UNDERLYING_ASSET_ADDRESS() external => CONSTANT;
    
    // called by AToken.sol::224. A method of IPool.
    function _.finalizeTransfer(address, address, address, uint256, uint256, uint256) external => NONDET;

    // called from: IncentivizedERC20.sol::29.
    function _.getACLManager() external => NONDET;

    // called from: IncentivizedERC20.sol::30.
    function _.isPoolAdmin(address) external => NONDET;

    // called from: IncentivizedERC20.sol::76.
    function _.ADDRESSES_PROVIDER() external => NONDET;

    // called from: IncentivizedERC20.sol::207. A method of incentivesControllerLocal.
    function _.handleAction(address,uint256,uint256) external => NONDET;
}

definition ZERO_ADDRESS() returns address = 0;


/*
    @Rule

    @Description:
    Integrity of permit function
    Successful permit function increases the nonce of owner by 1 and also changes the allowance of owner to spender

    @Formula:
    {
        nonceBefore = getNonce(owner)
    }
    <
        permit(owner, spender, value, deadline, v, r, s)
    >
    {
        allowance(owner, spender) == value && getNonce(owner) == nonceBefore + 1
    }

    @Note:
        Written by https://github.com/parth-15

    @Link:
*/
rule permitIntegrity() {
    env e;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;

    uint256 allowanceBefore = allowance(owner, spender);
    mathint nonceBefore = getNonce(owner);

    //checking this because function is using unchecked math and such a high nonce is unrealistic
    require nonceBefore < max_uint;

    permit(e, owner, spender, value, deadline, v, r, s);

    uint256 allowanceAfter = allowance(owner, spender);
    mathint nonceAfter = getNonce(owner);

    assert allowanceAfter == value, "permit increases allowance of owner to spender on success";
    assert nonceAfter == nonceBefore + 1, "successful call to permit function increases nonce of owner by 1";
}


/*
    @Rule

    @Description:
        Verify that `metaDelegateByType` can only be called with a signed request.

    @Formula:
    {
        ecrecover(v,r,s) != delegator
    }
    <
        metaDelegateByType@withrevert(delegator, delegatee, delegationType, deadline, v, r, s)
    >
    {
        lastReverted == true
    }

    @Note:
        Written by https://github.com/kustosz

    @Link:
*/
rule metaDelegateByTypeOnlyCallableWithProperlySignedArguments(env e, address delegator, address delegatee, IBaseDelegation.GovernancePowerType delegationType, uint256 deadline, uint8 v, bytes32 r, bytes32 s) {
    require ecrecoverWrapper(computeMetaDelegateByTypeHash(delegator, delegatee, delegationType, deadline, getNonce(delegator)), v, r, s) != delegator;
    metaDelegateByType@withrevert(e, delegator, delegatee, delegationType, deadline, v, r, s);
    assert lastReverted;
}

 /*
    @Rule

    @Description:
        Verify that it's impossible to use the same arguments to call `metaDalegate` twice.

    @Formula:
    {
        hash1 = computeMetaDelegateHash(delegator, delegatee, deadline, nonce)
        hash2 = computeMetaDelegateHash(delegator, delegatee, deadline, nonce + 1)
        ecrecover(hash1, v, r, s) == delegator
    }
    <
        metaDelegate(e1, delegator, delegatee, v, r, s)
        metaDelegate@withrevert(e2, delegator, delegatee, delegationType, deadline, v, r, s)
    >
    {
        lastReverted == true
    }

    @Note:
        Written by https://github.com/kustosz

    @Link:
*/
rule metaDelegateNonRepeatable(env e1, env e2, address delegator, address delegatee, uint256 deadline, uint8 v, bytes32 r, bytes32 s) {
    uint256 nonce = getNonce(delegator);
    bytes32 hash1 = computeMetaDelegateHash(delegator, delegatee, deadline, nonce);
    bytes32 hash2 = computeMetaDelegateHash(delegator, delegatee, deadline, require_uint256(nonce+1));
    // assume no hash collisions
    require hash1 != hash2;
    // assume first call is properly signed
    require ecrecoverWrapper(hash1, v, r, s) == delegator;
    // assume ecrecover is sane: cannot sign two different messages with the same (v,r,s)
    require ecrecoverWrapper(hash2, v, r, s) != ecrecoverWrapper(hash1, v, r, s);
    metaDelegate(e1, delegator, delegatee, deadline, v, r, s);
    metaDelegate@withrevert(e2, delegator, delegatee, deadline, v, r, s);
    assert lastReverted;
}



/*
    @Rule

    @Description:
        Changing a delegate of one type doesn't influence the delegate of the other type

    @Formula:
    {
        delegateBefore = type == 1 ? getPropositionDelegatee(e.msg.sender) : getVotingDelegatee(e.msg.sender)
    }
    <
        delegateByType(e, delegatee, 1 - type)
    >
    {
       delegateBefore = type == 1 ? getPropositionDelegatee(e.msg.sender) : getVotingDelegatee(e.msg.sender)
       delegateBefore == delegateAfter
    }

    @Note:
        Written by https://github.com/top-sekret

    @Link:
*/
rule delegateIndependence(method f) {
    env e;

    IBaseDelegation.GovernancePowerType type;

    address delegateBefore = type == IBaseDelegation.GovernancePowerType.PROPOSITION ? getPropositionDelegatee(e.msg.sender) : getVotingDelegatee(e.msg.sender);

    IBaseDelegation.GovernancePowerType otherType = type == IBaseDelegation.GovernancePowerType.PROPOSITION ? IBaseDelegation.GovernancePowerType.VOTING : IBaseDelegation.GovernancePowerType.PROPOSITION;
    delegateByType(e, _, otherType);

    address delegateAfter = type == IBaseDelegation.GovernancePowerType.PROPOSITION ? getPropositionDelegatee(e.msg.sender) : getVotingDelegatee(e.msg.sender);

    assert delegateBefore == delegateAfter;
}

/*
    @Rule

    @Description:
        Verifying voting power increases/decreases while not being a voting delegatee yourself

    @Formula:
    {
        votingPowerBefore = getPowerCurrent(a, VOTING_POWER)
        balanceBefore = balanceOf(a)
        isVotingDelegatorBefore = isDelegatingVoting(a)
        isVotingDelegateeBefore = getDelegatedVotingBalance(a) != 0
    }
    <
        f(e, args)
    >
    {
        votingPowerAfter = getPowerCurrent(a, VOTING_POWER()
        balanceAfter = getBalance(a)
        isVotingDelegatorAfter = isDelegatingVoting(a);
        isVotingDelegateeAfter = getDelegatedVotingBalance(a) != 0

        votingPowerBefore < votingPowerAfter <=> 
        (!isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore < balanceAfter)) ||
        (isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore != 0))
        &&
        votingPowerBefore > votingPowerAfter <=> 
        (!isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore > balanceAfter)) ||
        (!isVotingDelegatorBefore && isVotingDelegatorAfter && (balanceBefore != 0))
    }

    @Note:
        Written by https://github.com/Zarfsec

    @Link:
*/
rule votingPowerChangesWhileNotBeingADelegatee(address a) {
    //For delegation rules we require that index==1.
    require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());

    require a != 0;

    uint256 votingPowerBefore = getPowerCurrent(a, VOTING_POWER());
    uint256 balanceBefore = balanceOf(a); //getBalance(a);
    bool isVotingDelegatorBefore = isDelegatingVoting(a);
    bool isVotingDelegateeBefore = getDelegatedVotingBalance(a) != 0;

    method f;
    env e;
    calldataarg args;
    f(e, args);

    // For delegation rules we require that index==1.
    require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());

    uint256 votingPowerAfter = getPowerCurrent(a, VOTING_POWER());
    uint256 balanceAfter = balanceOf(a); //getBalance(a);
    bool isVotingDelegatorAfter = isDelegatingVoting(a);
    bool isVotingDelegateeAfter = getDelegatedVotingBalance(a) != 0;

    require !isVotingDelegateeBefore && !isVotingDelegateeAfter;

    /* 
    If you're not a delegatee, your voting power only increases when
        1. You're not delegating and your balance increases
        2. You're delegating and stop delegating and your balanceBefore != 0
    */
    assert votingPowerBefore < votingPowerAfter <=> 
        (!isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore < balanceAfter)) ||
        (isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore != 0));

    /*
    If you're not a delegatee, your voting power only decreases when
        1. You're not delegating and your balance decreases
        2. You're not delegating and start delegating and your balanceBefore != 0
    */
    assert votingPowerBefore > votingPowerAfter <=> 
        (!isVotingDelegatorBefore && !isVotingDelegatorAfter && (balanceBefore > balanceAfter)) ||
        (!isVotingDelegatorBefore && isVotingDelegatorAfter && (balanceBefore != 0));
}

/*
    @Rule

    @Description:
        Verifying proposition power increases/decreases while not being a proposition delegatee yourself

    @Formula:
    {
        propositionPowerBefore = getPowerCurrent(a, PROPOSITION_POWER)
        balanceBefore = balanceOf(a)
        isPropositionDelegatorBefore = isDelegatingProposition(a)
        isPropositionDelegateeBefore = getDelegatedPropositionBalance(a) != 0
    }
    <
        f(e, args)
    >
    {
        propositionPowerAfter = getPowerCurrent(a, PROPOSITION_POWER()
        balanceAfter = getBalance(a)
        isPropositionDelegatorAfter = isDelegatingProposition(a);
        isPropositionDelegateeAfter = getDelegatedPropositionBalance(a) != 0

        propositionPowerBefore < propositionPowerAfter <=> 
        (!isPropositionDelegatorBefore && !isPropositionDelegatorAfter && (balanceBefore < balanceAfter)) ||
        (isPropositionDelegatorBefore && !isPropositionDelegatorAfter && (balanceBefore != 0))
        &&
        propositionPowerBefore > propositionPowerAfter <=> 
        (!isPropositionDelegatorBefore && !isPropositionDelegatorAfter && (balanceBefore > balanceAfter)) ||
        (!isPropositionDelegatorBefore && isPropositionDelegatorAfter && (balanceBefore != 0))
    }

    @Note:
        Written by https://github.com/Zarfsec

    @Link:
*/
rule propositionPowerChangesWhileNotBeingADelegatee(address a) {
    // For delegation rules we require that index==1.
    require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());

    require a != 0;

    uint256 propositionPowerBefore = getPowerCurrent(a, PROPOSITION_POWER());
    uint256 balanceBefore = balanceOf(a); //getBalance(a);
    bool isPropositionDelegatorBefore = isDelegatingProposition(a);
    bool isPropositionDelegateeBefore = getDelegatedPropositionBalance(a) != 0;

    method f;
    env e;
    calldataarg args;
    f(e, args);

    // For delegation rules we require that index==1.
    require (_SymbolicLendingPoolL1.getReserveNormalizedIncome(Underlying) == RAY());

    uint256 propositionPowerAfter = getPowerCurrent(a, PROPOSITION_POWER());
    uint256 balanceAfter = balanceOf(a); //getBalance(a);
    bool isPropositionDelegatorAfter = isDelegatingProposition(a);
    bool isPropositionDelegateeAfter = getDelegatedPropositionBalance(a) != 0;

    require !isPropositionDelegateeBefore && !isPropositionDelegateeAfter;

    /*
    If you're not a delegatee, your proposition power only increases when
        1. You're not delegating and your balance increases
        2. You're delegating and stop delegating and your balanceBefore != 0
    */
    assert propositionPowerBefore < propositionPowerAfter <=> 
        (!isPropositionDelegatorBefore && !isPropositionDelegatorAfter && (balanceBefore < balanceAfter)) ||
        (isPropositionDelegatorBefore && !isPropositionDelegatorAfter && (balanceBefore != 0));
    
    /*
    If you're not a delegatee, your proposition power only decreases when
        1. You're not delegating and your balance decreases
        2. You're not delegating and start delegating and your balanceBefore != 0
    */
    assert propositionPowerBefore > propositionPowerAfter <=> 
        (!isPropositionDelegatorBefore && !isPropositionDelegatorBefore && (balanceBefore > balanceAfter)) ||
        (!isPropositionDelegatorBefore && isPropositionDelegatorAfter && (balanceBefore != 0));
}


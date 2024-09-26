
import "../methods/methods_base.spec";

////////////////// FUNCTIONS //////////////////////

    /// @title Sum of scaled balances of AToken 
    ghost mathint sumAllATokenScaledBalance  {
        init_state axiom sumAllATokenScaledBalance == 0;
    }


    /// @dev sample struct UserState {uint128 balance; uint128 additionalData; }
    hook Sstore _AToken._userState[KEY address a] .(offset 0) uint128 balance (uint128 old_balance) {
      sumAllATokenScaledBalance = sumAllATokenScaledBalance + balance - old_balance;
      //      havoc sumAllATokenScaledBalance() assuming sumAllATokenScaledBalance()@new() == sumAllATokenScaledBalance()@old() + balance - old_balance;
    }

    hook Sload uint128 balance _AToken._userState[KEY address a] .(offset 0) {
        require to_mathint(balance) <= sumAllATokenScaledBalance;
    } 

///////////////// Properties ///////////////////////

    /**
    * @title User AToken balance is fixed
    * Interaction with `StaticAtokenLM` should not change a user's AToken balance,
    * except for the following methods:
    * - `withdraw`
    * - `deposit`
    * - `redeem`
    * - `mint`
    * - `metaDeposit`
    * - `metaWithdraw`
    *
    * Note. Rewards methods are special cases handled in other rules below.
    *
    * Rules passed (with rule sanity): job-id=`5fdaf5eeaca249e584c2eef1d66d73c7`
    *
    * Note. `UNDERLYING_ASSET_ADDRESS()` was unresolved!
    */
    rule aTokenBalanceIsFixed(method f) filtered {
        // Exclude balance changing methods
        f -> (f.selector != sig:depositATokens(uint256,address).selector) &&
          (f.selector != sig:withdraw(uint256,address,address).selector) &&
          (f.selector != sig:redeemATokens(uint256,address,address).selector) &&
          (f.selector != sig:mint(uint256,address).selector) &&
          (f.selector != sig:collectAndUpdateRewards(address).selector) &&
          (f.selector != sig:claimRewardsOnBehalf(address,address,address[]).selector) &&
          (f.selector != sig:claimSingleRewardOnBehalf(address,address,address).selector) &&
          (f.selector != sig:claimRewardsToSelf(address[]).selector) &&
          (f.selector != sig:claimRewards(address,address[]).selector)
    } {

        env e;

        // Limit sender
        require e.msg.sender != currentContract;
        require e.msg.sender != _AToken;

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        calldataarg args;
        f(e, args);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by static interaction";
    }

    rule aTokenBalanceIsFixed_for_collectAndUpdateRewards() {
        env e;

        // Limit sender
        require e.msg.sender != currentContract;
        require e.msg.sender != _AToken;
        require e.msg.sender != _DummyERC20_rewardToken;

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        collectAndUpdateRewards(e, _DummyERC20_rewardToken);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by collectAndUpdateRewards";
    }


    rule aTokenBalanceIsFixed_for_claimRewardsOnBehalf(address onBehalfOf, address receiver) {
        // Create a rewards array
        address[] _rewards;
        require _rewards[0] == _DummyERC20_rewardToken;
        require _rewards.length == 1;

        env e;

        // Limit sender
        require (
            (e.msg.sender != currentContract) &&
            (onBehalfOf != currentContract) &&
            (receiver != currentContract)
        );
        require (
            (e.msg.sender != _DummyERC20_rewardToken) &&
            (onBehalfOf != _DummyERC20_rewardToken) &&
            (receiver != _DummyERC20_rewardToken)
        );
        require (e.msg.sender != _AToken) && (onBehalfOf != _AToken) && (receiver != _AToken);

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        claimRewardsOnBehalf(e, onBehalfOf, receiver, _rewards);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by claimRewardsOnBehalf";
    }


    rule aTokenBalanceIsFixed_for_claimSingleRewardOnBehalf(address onBehalfOf, address receiver) {
        env e;

        // Limit sender
        require (
            (e.msg.sender != currentContract) &&
            (onBehalfOf != currentContract) &&
            (receiver != currentContract)
        );
        require (
            (e.msg.sender != _DummyERC20_rewardToken) &&
            (onBehalfOf != _DummyERC20_rewardToken) &&
            (receiver != _DummyERC20_rewardToken)
        );
        require (e.msg.sender != _AToken) && (onBehalfOf != _AToken) && (receiver != _AToken);

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        claimSingleRewardOnBehalf(e, onBehalfOf, receiver, _DummyERC20_rewardToken);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by claimSingleRewardOnBehalf";
    }


    rule aTokenBalanceIsFixed_for_claimRewardsToSelf() {
        // Create a rewards array
        address[] _rewards;
        require _rewards[0] == _DummyERC20_rewardToken;
        require _rewards.length == 1;

        env e;

        // Limit sender
        require e.msg.sender != currentContract;
        require e.msg.sender != _AToken;
        require e.msg.sender != _DummyERC20_rewardToken;

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        claimRewardsToSelf(e, _rewards);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by claimRewardsToSelf";
    }


    rule aTokenBalanceIsFixed_for_claimRewards(address receiver) {
        // Create a rewards array
        address[] _rewards;
        require _rewards[0] == _DummyERC20_rewardToken;
        require _rewards.length == 1;

        env e;

        // Limit sender
        require (e.msg.sender != currentContract) && (receiver != currentContract);
        require (
            (e.msg.sender != _DummyERC20_rewardToken) && (receiver != _DummyERC20_rewardToken)
        );
        require (e.msg.sender != _AToken) && (receiver != _AToken);

        uint256 preBalance = _AToken.balanceOf(e.msg.sender);

        claimRewards(e, receiver, _rewards);

        uint256 postBalance = _AToken.balanceOf(e.msg.sender);
        assert preBalance == postBalance, "aToken balance changed by claimRewards";
    }

    /// @title AToken balancerOf(user) <= AToken totalSupply()
    //timeout on redeem metaWithdraw
    //error when running with rule_sanity
    //https://vaas-stg.certora.com/output/99352/509a56a1d46348eea0872b3a57c4d15a/?anonymousKey=3e15ac5a5b01e689eb3f71580e3532d8098e71b5
    invariant inv_atoken_balanceOf_leq_totalSupply(address user)
        _AToken.balanceOf(user) <= _AToken.totalSupply()
        filtered { f ->
        !f.isView &&
        f.selector != sig:redeem(uint256,address,address).selector &&
        f.selector != sig:redeemATokens(uint256,address,address).selector &&
        f.selector != sig:emergencyEtherTransfer(address,uint256).selector &&
        !harnessOnlyMethods(f)}
        {
            preserved with (env e){
                requireInvariant sumAllATokenScaledBalance_eq_totalSupply();
            }
        }

    /// @title AToken balancerOf(user) <= AToken totalSupply()
    /// @dev case split of inv_atoken_balanceOf_leq_totalSupply
    //pass, times out with rule_sanity basic
    invariant inv_atoken_balanceOf_leq_totalSupply_redeem(address user)
        _AToken.balanceOf(user) <= _AToken.totalSupply()
    filtered { f -> f.selector == sig:redeem(uint256,address,address).selector }
        {
            preserved with (env e){
                requireInvariant sumAllATokenScaledBalance_eq_totalSupply();
            }
        }

    /// @title AToken balancerOf(user) <= AToken totalSupply()
    /// @dev case split of inv_atoken_balanceOf_leq_totalSupply
    //pass, times out with rule_sanity basic
    invariant inv_atoken_balanceOf_leq_totalSupply_redeemAToken(address user)
        _AToken.balanceOf(user) <= _AToken.totalSupply()
    filtered { f -> f.selector == sig:redeemATokens(uint256,address,address).selector }
        {
            preserved with (env e){
                requireInvariant sumAllATokenScaledBalance_eq_totalSupply();
            }
        }

    /// @title Sum of AToken scaled balances = AToken scaled totalSupply()
    //pass with rule_sanity basic
    //https://vaas-stg.certora.com/output/99352/4f91637a96d647baab9accb1093f1690/?anonymousKey=53ccda4a9dd8988205d4b614d9989d1e4148533f
    invariant sumAllATokenScaledBalance_eq_totalSupply()
      sumAllATokenScaledBalance == to_mathint(_AToken.scaledTotalSupply())
    filtered { f -> !harnessOnlyMethods(f) }


    /// @title AToken scaledBalancerOf(user) <= AToken scaledTotalSupply()
    //pass with rule_sanity basic
    //https://vaas-stg.certora.com/output/99352/6798b502f97a4cd2b05fce30947911c0/?anonymousKey=c5808a8997a75480edbc45153165c8763488cd1e
    invariant inv_atoken_scaled_balanceOf_leq_totalSupply(address user)
        _AToken.scaledBalanceOf(user) <= _AToken.scaledTotalSupply()
    filtered { f -> !harnessOnlyMethods(f) }
        {
            preserved {
                requireInvariant sumAllATokenScaledBalance_eq_totalSupply();
            }
        }

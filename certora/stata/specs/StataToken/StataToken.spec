import "../methods/methods_base.spec";

/////////////////// Methods ////////////////////////

    methods {   
        function _.getIncentivesController() external => CONSTANT;
        function _.getRewardsList() external => NONDET;
            //call by RewardsController.IncentivizedERC20.sol and also by StaticATokenLM.sol
        function _.handleAction(address,uint256,uint256) external => DISPATCHER(true);

        function balanceOf(address) external returns (uint256) envfree;
        function totalSupply() external returns (uint256) envfree;
    }


///////////////// Properties ///////////////////////

    /**
    * @title Rewards claiming when sufficient rewards exist
    * Ensures rewards are updated correctly after claiming, when there are enough
    * reward funds.
    *
    * @dev Passed in job-id=`655ba8737ada43efab71eaabf8d41096`
    */
    rule rewardsConsistencyWhenSufficientRewardsExist() {
        // Assuming single reward
        single_RewardToken_setup();

        // Create a rewards array
        address[] _rewards;
        require _rewards[0] == _DummyERC20_rewardToken;
        require _rewards.length == 1;

        env e;
        require e.msg.sender != currentContract;  // Cannot claim to contract
        uint256 rewardsBalancePre = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        uint256 claimablePre = getClaimableRewards(e, e.msg.sender, _DummyERC20_rewardToken);

        // Ensure contract has sufficient rewards
        require _DummyERC20_rewardToken.balanceOf(currentContract) >= claimablePre;

        claimRewardsToSelf(e, _rewards);

        uint256 rewardsBalancePost = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        uint256 unclaimedPost = getUnclaimedRewards(e.msg.sender, _DummyERC20_rewardToken);
        uint256 claimablePost = getClaimableRewards(e, e.msg.sender, _DummyERC20_rewardToken);
        
        assert rewardsBalancePost >= rewardsBalancePre, "Rewards balance reduced after claim";
        mathint rewardsGiven = rewardsBalancePost - rewardsBalancePre;
        assert to_mathint(claimablePre) == rewardsGiven + unclaimedPost, "Rewards given unequal to claimable";
        assert claimablePost == unclaimedPost, "Claimable different from unclaimed";
        assert unclaimedPost == 0;  // Left last as this is an implementation detail
    }

    /**
    * @title Rewards claiming when rewards are insufficient
    * Ensures rewards are updated correctly after claiming, when there aren't
    * enough funds.
    */
    rule rewardsConsistencyWhenInsufficientRewards() {
        // Assuming single reward
        single_RewardToken_setup();

        env e;
        require e.msg.sender != currentContract;  // Cannot claim to contract
        require e.msg.sender != _TransferStrategy;

        uint256 rewardsBalancePre = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        uint256 claimablePre = getClaimableRewards(e, e.msg.sender, _DummyERC20_rewardToken);

        // Ensure contract does not have sufficient rewards
        require _DummyERC20_rewardToken.balanceOf(currentContract) < claimablePre;

        claimSingleRewardOnBehalf(e, e.msg.sender, e.msg.sender, _DummyERC20_rewardToken);

        uint256 rewardsBalancePost = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        uint256 unclaimedPost = getUnclaimedRewards(e.msg.sender, _DummyERC20_rewardToken);
        uint256 claimablePost = getClaimableRewards(e, e.msg.sender, _DummyERC20_rewardToken);
        
        assert rewardsBalancePost >= rewardsBalancePre, "Rewards balance reduced after claim";
        mathint rewardsGiven = rewardsBalancePost - rewardsBalancePre;
        // Note, when `rewardsGiven` is 0 the unclaimed rewards are not updated
        assert (
            ( (rewardsGiven > 0) => (to_mathint(claimablePre) == rewardsGiven + unclaimedPost) ) &&
            ( (rewardsGiven == 0) => (claimablePre == claimablePost) )
            ), "Claimable rewards changed unexpectedly";
    }


    /**
    * @title Only claiming rewards should reduce contract's total rewards balance
    * Only "claim reward" methods should cause the total rewards balance of
    * `StaticATokenLM` to decline. Note that `initialize` and `emergencyEtherTransfer`
    * are filtered out. To avoid timeouts the rest of the
    * methods were split between several versions of this rule.
    *
    * @dev Passed with rule-sanity in job-id=`98beb842d5b94278ac4a9222249fb564`
    * 
    */
    rule rewardsTotalDeclinesOnlyByClaim(method f) filtered {
      f -> (
            f.contract == currentContract &&
            !harnessOnlyMethods(f) &&
            f.selector != sig:initialize(address, string, string).selector) &&
            f.selector != sig:emergencyEtherTransfer(address,uint256).selector &&
            f.selector != sig:emergencyTokenTransfer(address,address,uint256).selector
        } {
        // Assuming single reward
        single_RewardToken_setup();
        rewardsController_reward_setup();

        require _AToken.UNDERLYING_ASSET_ADDRESS() == _DummyERC20_aTokenUnderlying;

        env e;
        require e.msg.sender != currentContract;
        uint256 preTotal = getTotalClaimableRewards(e, _DummyERC20_rewardToken);

        calldataarg args;
        f(e, args);

        uint256 postTotal = getTotalClaimableRewards(e, _DummyERC20_rewardToken);

        assert (postTotal < preTotal) => (
            (f.selector == sig:claimRewardsOnBehalf(address, address, address[]).selector) ||
            (f.selector == sig:claimRewards(address, address[]).selector) ||
            (f.selector == sig:claimRewardsToSelf(address[]).selector) ||
            (f.selector == sig:claimSingleRewardOnBehalf(address,address,address).selector)
        ), "Total rewards decline due to function other than claim or emergency rescue";
    }

    //pass -t=1400,-mediumTimeout=800,-depth=10 
    /// @notice Total supply is non-zero  only if total assets is non-zero
    invariant solvency_positive_total_supply_only_if_positive_asset()
    ((_AToken.scaledBalanceOf(currentContract) == 0) => (totalSupply() == 0))
    filtered { f ->
        f.contract == currentContract 
        && !harnessMethodsMinusHarnessClaimMethods(f) 
        && !claimFunctions(f)
        && f.selector != sig:claimDoubleRewardOnBehalfSame(address, address, address).selector
        && f.selector != sig:emergencyEtherTransfer(address,uint256).selector
        }
            {
            preserved redeem(uint256 shares, address receiver, address owner) with (env e1) {
                requireInvariant solvency_total_asset_geq_total_supply();
                require balanceOf(owner) <= totalSupply();
            }
            preserved redeemATokens(uint256 shares, address receiver, address owner) with (env e2) {
                requireInvariant solvency_total_asset_geq_total_supply();
                require balanceOf(owner) <= totalSupply(); 
            }
            preserved withdraw(uint256 assets, address receiver, address owner)  with (env e3) {
                requireInvariant solvency_total_asset_geq_total_supply();
                require balanceOf(owner) <= totalSupply(); 
            }
            preserved emergencyTokenTransfer(address asset, address to, uint256 amount) with (env e3) {
                require rate() >= RAY();
            }
            }



    //pass with -t=1400,-mediumTimeout=800,-depth=15
    //https://vaas-stg.certora.com/output/99352/7252b6b75144419c825fb00f1f11acc8/?anonymousKey=8cb67238d3cb2a14c8fbad5c1c8554b00221de95
    //pass with -t=1400,-mediumTimeout=800,-depth=10

    /// @nitce Total assets is greater than or equal to total supply.
    invariant solvency_total_asset_geq_total_supply()
    (_AToken.scaledBalanceOf(currentContract) >= totalSupply())
        filtered { f ->
        f.contract == currentContract 
        && !harnessMethodsMinusHarnessClaimMethods(f)
        && !claimFunctions(f)
        && f.selector != sig:emergencyEtherTransfer(address,uint256).selector
        && f.selector != sig:claimDoubleRewardOnBehalfSame(address, address, address).selector }
        {
            preserved withdraw(uint256 assets, address receiver, address owner)  with (env e3) {
                require balanceOf(owner) <= totalSupply(); 
            }
            preserved depositWithPermit(uint256 assets, address receiver, uint256 deadline, IERC4626StataToken.SignatureParams signature, bool depositToAave) with (env e4) {
                require balanceOf(receiver) <= totalSupply();
                require e4.msg.sender != currentContract;
            }
            preserved depositATokens(uint256 assets, address receiver) with (env e5) {
                require balanceOf(receiver) <= totalSupply();
                require e5.msg.sender != currentContract;
            }
            preserved deposit(uint256 assets, address receiver) with (env e5) {
                require balanceOf(receiver) <= totalSupply();
                require e5.msg.sender != currentContract;
            }
            preserved mint(uint256 shares, address receiver) with (env e6) {
                require balanceOf(receiver) <= totalSupply();
                require e6.msg.sender != currentContract;
            }
            preserved redeem(uint256 shares, address receiver, address owner) with (env e2) {
                require balanceOf(owner) <= totalSupply(); 
            }
            preserved redeemATokens(uint256 shares, address receiver, address owner) with (env e2) {
                require balanceOf(owner) <= totalSupply(); 
            }
            preserved emergencyTokenTransfer(address asset, address to, uint256 amount) with (env e1) {
                require rate() >= RAY();
            }
        }

        

    //pass
    /// @title correct accrued value is fetched
    /// @notice assume a single asset
    //pass with rule_sanity basic except metaDeposit()
    //https://vaas-stg.certora.com/output/99352/ab6c92a9f96d4327b52da331d634d3ab/?anonymousKey=abb27f614a8656e6e300ce21c517009cbe0c4d3a
    //https://vaas-stg.certora.com/output/99352/d8c9a8bbea114d5caad43683b06d8ba0/?anonymousKey=a079d7f7dd44c47c05c866808c32235d56bca8e8
    invariant singleAssetAccruedRewards(env e0, address _asset, address reward, address user)
    ((_RewardsController.getAssetListLength() == 1 && _RewardsController.getAssetByIndex(0) == _asset)
    => (_RewardsController.getUserAccruedReward(_asset, reward, user) == _RewardsController.getUserAccruedRewards(reward, user)))
    filtered {f ->
                f.contract == currentContract &&
                f.selector != sig:emergencyEtherTransfer(address,uint256).selector &&
                !harnessOnlyMethods(f) 
            } 
    {
        preserved with (env e1){
            setup(e1, user);
            require _asset != _RewardsController;
            require _asset != _TransferStrategy;
            require reward != _StaticATokenLM;
            require reward != _AToken;
            require reward != _TransferStrategy;
        }
    }



    //pass with --rule_sanity basic
    //https://vaas-stg.certora.com/output/99352/4df615c845e2445b8657ece2db477ce5/?anonymousKey=76379915d60fc1056ed4e5b391c69cd5bba3cce0
    /// @title Claiming rewards should not affect totalAssets() 
    rule totalAssets_stable(method f)
        filtered { f -> f.selector == sig:claimSingleRewardOnBehalf(address, address, address).selector 
                     || f.selector == sig:collectAndUpdateRewards(address).selector }
    {
        env e;
        calldataarg args;
        mathint totalAssetBefore = totalAssets();
        f(e, args); 
        mathint totalAssetAfter = totalAssets();
        assert totalAssetAfter == totalAssetBefore;
    }

    /// @title getTotalClaimableRewards() is stable unless rewards were claimed or emergency rescue was applied
    rule totalClaimableRewards_stable(method f)
        filtered { f -> 
                    f.contract == currentContract
                    && !f.isView
                    && !claimFunctions(f)
                    && !collectAndUpdateFunction(f)
                    && !harnessOnlyMethods(f)
                    && f.selector != sig:initialize(address,string,string).selector 
                    && f.selector != sig:emergencyEtherTransfer(address,uint256).selector 
                    && f.selector != sig:emergencyTokenTransfer(address,address,uint256).selector
                 }
        {
            env e;
            require e.msg.sender != currentContract;
            setup(e, 0);
            calldataarg args;
            address reward;
            require e.msg.sender != reward ;
            require currentContract != e.msg.sender;
            require _AToken != e.msg.sender;
            require _RewardsController != e.msg.sender;
            require _DummyERC20_aTokenUnderlying  != e.msg.sender;
            require _DummyERC20_rewardToken != e.msg.sender;
            require _SymbolicLendingPool != e.msg.sender;
            require _TransferStrategy != e.msg.sender;
            
            require currentContract != reward;
            require _AToken != reward;
            require _RewardsController !=  reward;
            require _DummyERC20_aTokenUnderlying  != reward;
            require _SymbolicLendingPool != reward;
            require _TransferStrategy != reward;
            require _TransferStrategy != reward;


            mathint totalClaimableRewardsBefore = getTotalClaimableRewards(e, reward);
            f(e, args); 
            mathint totalClaimableRewardsAfter = getTotalClaimableRewards(e, reward);
            assert  totalClaimableRewardsAfter == totalClaimableRewardsBefore;
        }



    //pass with -t=1400,-mediumTimeout=800,-depth=15
    //https://vaas-stg.certora.com/output/99352/a10c05634b4342d6b31f777826444616/?anonymousKey=67bb71ebd716ef5d10be8743ded7b466f699e32c
    //pass with -t=1400,-mediumTimeout=800,-depth=10 
rule getClaimableRewards_stable(method f)
  filtered { f ->
    f.contract == currentContract &&
    !f.isView
    && !claimFunctions(f)
    && !collectAndUpdateFunction(f)
    && f.selector != sig:initialize(address,string,string).selector
    && f.selector != sig:emergencyEtherTransfer(address,uint256).selector
    && !harnessOnlyMethods(f)
    }
    {
        env e;
        calldataarg args;
        address user;
        address reward;
    
        require user != 0;

        require currentContract != reward;
        require _AToken != reward;
        require _RewardsController !=  reward; //
        require _DummyERC20_aTokenUnderlying  != reward;
        require _SymbolicLendingPool != reward; 
        require _TransferStrategy != reward;
        
        //require isRegisteredRewardToken(reward); //todo: review the assumption
    
        mathint claimableRewardsBefore = getClaimableRewards(e, user, reward);

        require getRewardTokensLength() > 0;
        require getRewardToken(0) == reward; //todo: review
        require _RewardsController.getAvailableRewardsCount(_AToken)  > 0; //todo: review
        require _RewardsController.getRewardsByAsset(_AToken, 0) == reward; //todo: review
        f(e, args); 
        mathint claimableRewardsAfter = getClaimableRewards(e, user, reward);
        assert claimableRewardsAfter == claimableRewardsBefore;
    }



    //pass
    rule getClaimableRewards_stable_after_deposit()
    {
        env e;
        address user;
        address reward;
        
        uint256 assets;
        address recipient;
        // uint16 referralCode;
        // bool fromUnderlying;

        require user != 0;

        
        mathint claimableRewardsBefore = getClaimableRewards(e, user, reward);
        require getRewardTokensLength() > 0;
        require getRewardToken(0) == reward; //todo: review

        require _RewardsController.getAvailableRewardsCount(_AToken)  > 0; //todo: review
        require _RewardsController.getRewardsByAsset(_AToken, 0) == reward; //todo: review
        // deposit(e, assets, recipient,referralCode,fromUnderlying);
        depositATokens(e, assets, recipient); // try depositWithPermit()
        mathint claimableRewardsAfter = getClaimableRewards(e, user, reward);
        assert claimableRewardsAfter == claimableRewardsBefore;
    }


    
    //todo: remove
    //pass with --loop_iter=2 --rule_sanity basic
    //https://vaas-stg.certora.com/output/99352/290a1108baa64316ac4f20b5501b4617/?anonymousKey=930379a90af5aa498ec3fed2110a08f5c096efb3
    /// @title getClaimableRewards() is stable unless rewards were claimed
    rule getClaimableRewards_stable_after_refreshRewardTokens()
    {
        env e;
        address user;
        address reward;

        mathint claimableRewardsBefore = getClaimableRewards(e, user, reward);
        refreshRewardTokens(e);

        mathint claimableRewardsAfter = getClaimableRewards(e, user, reward);
        assert claimableRewardsAfter == claimableRewardsBefore;
    }


    /// @title The amount of rewards that was actually received by claimRewards() cannot exceed the initial amount of rewards
    rule getClaimableRewardsBefore_leq_claimed_claimRewardsOnBehalf(method f)
    {
        env e;
        address onBehalfOf;
        address receiver;
        require receiver != currentContract;
        
        mathint balanceBefore = _DummyERC20_rewardToken.balanceOf(receiver);
        mathint claimableRewardsBefore = getClaimableRewards(e, onBehalfOf, _DummyERC20_rewardToken);
        claimSingleRewardOnBehalf(e, onBehalfOf, receiver, _DummyERC20_rewardToken);
        mathint balanceAfter = _DummyERC20_rewardToken.balanceOf(receiver);
        mathint deltaBalance = balanceAfter - balanceBefore;

        assert deltaBalance <= claimableRewardsBefore;
    }

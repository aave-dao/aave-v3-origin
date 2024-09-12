import "../methods/methods_multi_reward.spec";

///////////////// Properties ///////////////////////

    /// @dev Broke the rule into two cases to speed up verification

    /**
     * @title Claiming the same reward twice assuming sufficient rewards
     * Using an array with the same reward twice does not give more rewards,
     * assuming the contract has sufficient rewards.
     *
     * @dev Passed in job-id=`54de623f62eb4c95a343ee38834c6d16`
     */
    rule prevent_duplicate_reward_claiming_single_reward_sufficient() {
        single_RewardToken_setup();
        rewardsController_arbitrary_single_reward_setup();

        env e;
        require e.msg.sender != currentContract;  // Cannot claim to contract

        uint256 initialBalance = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        mathint claimable = getClaimableRewards(e, e.msg.sender,_DummyERC20_rewardToken);

        // Ensure contract has sufficient rewards
        require to_mathint(_DummyERC20_rewardToken.balanceOf(currentContract)) >= claimable;

        // Duplicate claim
        claimDoubleRewardOnBehalfSame(e, e.msg.sender, e.msg.sender, _DummyERC20_rewardToken);
        
        uint256 duplicateClaimBalance = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        mathint diff = duplicateClaimBalance - initialBalance;
        uint256 unclaimed = getUnclaimedRewards(e.msg.sender, _DummyERC20_rewardToken);

        assert diff + unclaimed <= claimable, "Duplicate claim changes rewards";
    }

    /**
     * @title Claiming the same reward twice assuming insufficient rewards
     * Using an array with the same reward twice does not give more rewards,
     * assuming the contract does not have sufficient rewards.
     *
     * @dev Passed in job-id=`54de623f62eb4c95a343ee38834c6d16`
     */
    rule prevent_duplicate_reward_claiming_single_reward_insufficient() {
        single_RewardToken_setup();
        rewardsController_arbitrary_single_reward_setup();

        env e;
        require e.msg.sender != currentContract;  // Cannot claim to contract

        uint256 initialBalance = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        mathint claimable = getClaimableRewards(e, e.msg.sender,_DummyERC20_rewardToken);

        // Ensure contract does not have sufficient rewards
        require to_mathint(_DummyERC20_rewardToken.balanceOf(currentContract)) < claimable;

        // Duplicate claim
        claimDoubleRewardOnBehalfSame(e, e.msg.sender, e.msg.sender, _DummyERC20_rewardToken);
        
        uint256 duplicateClaimBalance = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
        mathint diff = duplicateClaimBalance - initialBalance;
        uint256 unclaimed = getUnclaimedRewards(e.msg.sender, _DummyERC20_rewardToken);

        assert diff + unclaimed <= claimable, "Duplicate claim changes rewards";
    }

import "erc20.spec";

using SymbolicLendingPool as _SymbolicLendingPool;
using RewardsControllerHarness as _RewardsController;
using DummyERC20_aTokenUnderlying as _DummyERC20_aTokenUnderlying;
using ATokenInstance as _AToken;
using DummyERC20_rewardToken as _DummyERC20_rewardToken;

/////////////////// Methods ////////////////////////

    /// @dev Using mostly `NONDET` in the methods block, to speed up verification.

    methods {
        // static aToken
        // -------------
            function _.getCurrentRewardsIndex(address reward) external => CONSTANT;
            function getUnclaimedRewards(address, address) external returns (uint256) envfree;
            function rewardTokens() external returns (address[]) envfree;
            function isRegisteredRewardToken(address) external returns (bool) envfree;
        
        // static aToken harness
        // ---------------------
            function getRewardTokensLength() external returns (uint256) envfree;
            function getRewardToken(uint256) external returns (address) envfree;
    
        // pool
        // ----
            // In RewardsDistributor.sol called by RewardsController.sol
            function _.getAssetIndex(address, address) external => NONDET;

            // In RewardsDistributor.sol called by RewardsController.sol
            function _.finalizeTransfer(address, address, address, uint256, uint256, uint256) external => NONDET;

            // In ScaledBalanceTokenBase.sol called by getAssetIndex
            function _.scaledTotalSupply() external => DISPATCHER(true);

        // rewards controller
        // ------------------
            function _RewardsController.getAvailableRewardsCount(address) external returns (uint128) envfree;
            function _RewardsController.getRewardsByAsset(address, uint128) external returns (address) envfree;
            // Called by IncentivizedERC20.sol and by StaticATokenLM.sol
            function _.handleAction(address,uint256,uint256) external => NONDET;
            // Called by rewardscontroller.sol
            // Defined in scaledbalancetokenbase.sol
            function _.getScaledUserBalanceAndSupply(address) external => NONDET;
            // Called by RewardsController._transferRewards()
            // Defined in TransferStrategyHarness as simple transfer() 
            function _.performTransfer(address,address,uint256) external => NONDET;

        // aToken
        // ------
            function _AToken.UNDERLYING_ASSET_ADDRESS() external returns (address) envfree;
            function _.mint(address,address,uint256,uint256) external => NONDET;
            function _.burn(address,address,uint256,uint256) external => NONDET;
        
        // reward token
        // ------------
            function _DummyERC20_rewardToken.balanceOf(address) external returns (uint256) envfree;
        
            function _.permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external => NONDET;
    }

///////////////// FUNCTIONS ///////////////////////

    /// @title Set up a single reward token
    function single_RewardToken_setup() {
        require isRegisteredRewardToken(_DummyERC20_rewardToken);
        require getRewardTokensLength() == 1;
    }

    /// @title Set up a single reward token for `_AToken` in the `INCENTIVES_CONTROLLER`
    function rewardsController_arbitrary_single_reward_setup() {
        require _RewardsController.getAvailableRewardsCount(_AToken) == 1;
        require _RewardsController.getRewardsByAsset(_AToken, 0) == _DummyERC20_rewardToken;
    }

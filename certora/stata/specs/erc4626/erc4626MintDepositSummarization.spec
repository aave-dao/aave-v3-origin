import "../methods/erc20.spec";

using SymbolicLendingPool as _SymbolicLendingPool;
using ATokenInstance as _AToken;

/////////////////// Methods ////////////////////////

methods{
    // static aToken
    // -------------
        function asset() external returns (address) envfree;
    // erc20
    // -----
        function _.transferFrom(address,address,uint256) external => NONDET;

    // pool
        function _SymbolicLendingPool.getReserveNormalizedIncome(address) external returns (uint256) envfree;

    // aToken
    // ------
        function _AToken.UNDERLYING_ASSET_ADDRESS() external returns (address) envfree;
        function RAY() external returns (uint256) envfree;
}

///////////////// Properties ///////////////////////

    /********************
    *      deposit      *
    *********************/

        // The deposit function does not always deposit exactly the amount of assets specified by the user during the function call due to rounding error
        // The following two rules check that the user gets an non-zero amount of shares if the specified amount of assets to be deposited is at least
        // equivalent of 1 AToken. Refer to the erc4626DepositSummarization spec for rules asserting the upper bound of the amount of assets 
        // deposited in a deposit function call

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/b10cd30ab6fb400baeff6b61c07bb375/?anonymousKey=ccba22e832b7549efea9f0d4b1288da2c1377ccb
        ///@title Deposit function mint amount check for index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken 
        rule depositCheckIndexGRayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = deposit(e, assets, receiver);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }


        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/b10cd30ab6fb400baeff6b61c07bb375/?anonymousKey=ccba22e832b7549efea9f0d4b1288da2c1377ccb
        ///@title DepositATokens function mint amount check for index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken 
        rule depositATokensCheckIndexGRayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositATokens(e, assets, receiver);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/b10cd30ab6fb400baeff6b61c07bb375/?anonymousKey=ccba22e832b7549efea9f0d4b1288da2c1377ccb
        ///@title Deposit with permit function mint amount check for index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken 
        rule depositWithPermitCheckIndexGRayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 deadline;
            IERC4626StataToken.SignatureParams signature;
            bool depositToAave;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositWithPermit(e, assets, receiver, deadline, signature, depositToAave);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/2e162e12cafb49e688a7959a1d7dd4ca/?anonymousKey=d23ad1899e6bfa4e14fbf79799d008fa003dd633
        ///@title Deposit function mint amount check for index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken
        rule depositCheckIndexERayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = deposit(e, assets, receiver);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }
        
        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/2e162e12cafb49e688a7959a1d7dd4ca/?anonymousKey=d23ad1899e6bfa4e14fbf79799d008fa003dd633
        ///@title Deposit function mint amount check for index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken
        rule depositATokensCheckIndexERayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositATokens(e, assets, receiver);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/2e162e12cafb49e688a7959a1d7dd4ca/?anonymousKey=d23ad1899e6bfa4e14fbf79799d008fa003dd633
        ///@title Deposit function mint amount check for index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will mint atleast 1 share as long as the specified deposit amount is worth atleast 1 AToken
        rule depositWithPermitCheckIndexERayAssert2(env e){
            uint256 assets;
            address receiver;
            uint256 deadline;
            IERC4626StataToken.SignatureParams signature;
            bool depositToAave;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositWithPermit(e, assets, receiver, deadline, signature, depositToAave);
            
            assert assets * RAY() >= to_mathint(index) => shares != 0; //if the assets amount is worth at least 1 Atoken then receiver will get atleast 1 share
        }
    /*****************
    *      mint      *
    ******************/

        /***
        * rule to check the following for the mint function:
        * 1. MUST revert if all of shares cannot be minted
        */
        // The mint function doesn't always mint exactly the number of shares specified in the function call due to rounding off.
        // The following two rules check that the user will at least get as many shares they wanted to mint and upto one extra share
        // over the specified amount
        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/b6f6335e770b42ffa280e40d6f82906d/?anonymousKey=ed369d98039f29134aa774592c533ec0c4a9c08e
        ///@title mint function check for upper bound of shares minted
        ///@notice This rules checks that the mint function, for index  > RAY, mints upto 1 extra share over the amount specified by the caller
        rule mintCheckIndexGRayUpperBound(env e){
            uint256 shares;
            address receiver;
            uint256 assets;
            require e.msg.sender != currentContract;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());

            uint256 receiverBalBefore = balanceOf(e, receiver);
            require receiverBalBefore + shares <= max_uint256;//avoiding overflow
            require index > RAY();
            
            assets = mint(e, shares, receiver);
            
            uint256 receiverBalAfter = balanceOf(e, receiver);
            // upperbound
            assert to_mathint(receiverBalAfter) <= receiverBalBefore + shares + 1,"receiver should get no more than the 1 extra share";
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/d794a47fa37c4c1e9f9fcb45f33ec6c5/?anonymousKey=8a280f8c9ba94d2c0ce98a7240969c02828ad17b
        ///@title mint function check for lower bound of shares minted
        ///@notice This rules checks that the mint function, for index > RAY, mints atleast the amount of shares specified by the caller
        rule mintCheckIndexGRayLowerBound(env e){
            uint256 shares;
            address receiver;
            uint256 assets;
            require e.msg.sender != currentContract;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());

            uint256 receiverBalBefore = balanceOf(e, receiver);
            require receiverBalBefore + shares <= max_uint256;//avoiding overflow
            require index > RAY();
            
            assets = mint(e, shares, receiver);
            
            uint256 receiverBalAfter = balanceOf(e, receiver);
            // lowerbound
            assert to_mathint(receiverBalAfter) >= receiverBalBefore + shares,"receiver should get no less than the amount of shares requested";
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/bdf1ff3daa8542ebaac08c1950fdb89e/?anonymousKey=c5b77c1b715310da8f355d2b27bdb4008e70d519
        ///@title mint function check for index == RAY
        ///@notice This rule checks that, for index == RAY, the mind function will mint atleast the specifed amount of shares and upto 1 extra share over the specified amount
        rule mintCheckIndexEqualsRay(env e){
            uint256 shares;
            address receiver;
            uint256 assets;
            require e.msg.sender != currentContract;
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());

            uint256 receiverBalBefore = balanceOf(e, receiver);
            require receiverBalBefore + shares <= max_uint256;//avoiding overflow
            require index == RAY();
            
            assets = mint(e, shares, receiver);
            
            uint256 receiverBalAfter = balanceOf(e, receiver);
            
            assert to_mathint(receiverBalAfter) <= receiverBalBefore + shares + 1,"receiver should get no more than the 1 extra share";
            assert to_mathint(receiverBalAfter) >= receiverBalBefore + shares,"receiver should get no less than the amount of shares requested";
        }

import "../methods/methods_base.spec";

/////////////////// Methods ////////////////////////
    
methods{
    // static aToken
    // -------------
    function previewDeposit(uint256) external returns(uint256) envfree => NONDET;
    function ERC20Upgradeable._mint(address, uint256) internal => NONDET;

    // rewards controller
    // ------------------
    function _.handleAction(address, uint256, uint128) external => NONDET;
}

///////////////// Properties ///////////////////////

    /*********************
    *       deposit      *
    **********************/

        /***
        * rule to check the following for the deposit function:
        * 1. MUST revert if all of assets cannot be deposited
        */

        // The function doesn't always deposit exactly the asset amount specified by the user due to rounding. The amount deposited is within 1/2AToken of the 
        // amount specified by the user. The amount of shares minted would be zero for less than 1AToken worth of assets.
        // STATUS: Verified
        // https://prover.certora.com/output/11775/0c902c255ba748e99e9f7c2f50395706/?anonymousKey=aeb7ec100e687a415dd05c0eb9a45f823ceaeb25
        ///@title Deposit amount check for Index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will deposit upto 1 AToken more than the specified deposit amount
        rule depositCheckIndexGRayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = deposit(e, assets, receiver);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/RAY();
        }

        // The function doesn't always deposit exactly the asset amount specified by the user due to rounding. The amount deposited is within 1/2AToken of the 
        // amount specified by the user. The amount of shares minted would be zero for less than 1AToken worth of assets.
        // STATUS: Verified
        // https://prover.certora.com/output/11775/0c902c255ba748e99e9f7c2f50395706/?anonymousKey=aeb7ec100e687a415dd05c0eb9a45f823ceaeb25
        ///@title Deposit aTokens amount check for Index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will deposit upto 1 AToken more than the specified deposit amount
        rule depositATokensCheckIndexGRayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositATokens(e, assets, receiver);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/RAY();
        }

        // The function doesn't always deposit exactly the asset amount specified by the user due to rounding. The amount deposited is within 1/2AToken of the 
        // amount specified by the user. The amount of shares minted would be zero for less than 1AToken worth of assets.
        // STATUS: Verified
        // https://prover.certora.com/output/11775/0c902c255ba748e99e9f7c2f50395706/?anonymousKey=aeb7ec100e687a415dd05c0eb9a45f823ceaeb25
        ///@title Deposit with permit amount check for Index > RAY
        ///@notice This rule checks that, for index > RAY, the deposit function will deposit upto 1 AToken more than the specified deposit amount
        rule depositWithPermitCheckIndexGRayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 deadline;
            IERC4626StataToken.SignatureParams signature;
            bool depositToAave;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index > RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositWithPermit(e, assets, receiver, deadline, signature, depositToAave);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/RAY();
        }

        // STATUS: Verified
        //  https://prover.certora.com/output/11775/c149a926d08e44b98b05cec42ff97c0c/?anonymousKey=3a094dbfe8370e0ce3242e97cabd57a6df75a8c8
        ///@title Deposit amount check for Index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will deposit upto 1/2AToken more than the amount specified deposit amount
        rule depositCheckIndexERayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = deposit(e, assets, receiver);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/(2 * RAY());
        }

        // STATUS: Verified
        //  https://prover.certora.com/output/11775/c149a926d08e44b98b05cec42ff97c0c/?anonymousKey=3a094dbfe8370e0ce3242e97cabd57a6df75a8c8
        ///@title Deposit aTokens amount check for Index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will deposit upto 1/2AToken more than the amount specified deposit amount
        rule depositATokensCheckIndexERayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositATokens(e, assets, receiver);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/(2 * RAY());
        }

        // STATUS: Verified
        //  https://prover.certora.com/output/11775/c149a926d08e44b98b05cec42ff97c0c/?anonymousKey=3a094dbfe8370e0ce3242e97cabd57a6df75a8c8
        ///@title Deposit with permit amount check for Index == RAY
        ///@notice This rule checks that, for index == RAY, the deposit function will deposit upto 1/2AToken more than the amount specified deposit amount
        rule depositWithPermitCheckIndexERayAssert1(env e){
            uint256 assets;
            address receiver;
            uint256 deadline;
            IERC4626StataToken.SignatureParams signature;
            bool depositToAave;
            uint256 contractAssetBalBefore = _AToken.balanceOf(currentContract);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            
            require e.msg.sender != currentContract;
            require index == RAY();//since the index is initiated as RAY and only increases after that. index < RAY gives strange behaviors causing wildly inaccurate amounts being deposited and minted

            uint256 shares = depositWithPermit(e, assets, receiver, deadline, signature, depositToAave);

            uint256 contractAssetBalAfter = _AToken.balanceOf(currentContract);

            // upper bound for deposited assets
            assert contractAssetBalAfter - contractAssetBalBefore <= assets + index/(2 * RAY());
        }

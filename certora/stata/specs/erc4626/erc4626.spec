import "../methods/methods_base.spec";

methods {
    function balanceOf(address) external returns (uint256) envfree;
    function totalSupply() external returns (uint256) envfree;
    function ReserveConfiguration.getDecimals(DataTypes.ReserveConfigurationMap memory) internal returns (uint256) => limitReserveDecimals();
    function ReserveConfiguration.getSupplyCap(DataTypes.ReserveConfigurationMap memory) internal returns (uint256) => limitReserveSupplyCap();
}

///////////////// FUNCTIONS ///////////////////////

    function limitReserveDecimals() returns uint256 {
        uint256 dec;
        require dec >= 6 && dec <= 18;
        return dec;
    }

    function limitReserveSupplyCap() returns uint256 {
        uint256 cap;
        require cap <= 10^36;
        return cap;
    }


///////////////// Properties ///////////////////////
    /****************************
    *       previewDeposit      *
    *****************************/

        /***
        * rule to check the following for the previewDeposit function:
        * _1. MUST return as close to and no more than the exact amount of Vault shares that would 
        *     be minted in a deposit call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called in the same transaction.
        */
        // STATUS: Verified, that the amount returned by previewDeposit is exactly equal to that returned by the deposit function.
        //         This is a stronger property than the one required by the EIP.
        // https://vaas-stg.certora.com/output/11775/1488de4bb1e24d37a7972b0c2785df65/?anonymousKey=6f68dd14376fa7d0109ef2687f72d1ef1903dda8

        ///@title previewDeposit returns the right value
        ///@notice EIP4626 dictates that previewDeposit must return as close to and no more than the exact amount of Vault shares that would be minted in a deposit call in the same transaction. The previewDeposit function in staticAToken contract returns a value exactly equal to that returned by the deposit function.
        rule previewDepositAmountCheck(){
            env e1;
            env e2;
            uint256 assets;
            address receiver;   
            uint256 previewShares;
            uint256 shares;

            previewShares = previewDeposit(e1, assets);
            shares = deposit(e2, assets, receiver);

            assert previewShares == shares,"preview shares should be equal to actual shares";
        }

        // The EIP4626 spec requires that the previewDeposit function must not account for maxDeposit limit or the allowance of asset tokens.
        // The following rule checks that the value returned by the previewDeposit function is independent of allowance that the contract might have 
        // for transferring assets from any user.

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/05df2a231ec74da28ed10f627d3c7f72/?anonymousKey=70c692cbbf781597e0dc0b53a7d4ed6968bb467a

        ///@title previewDeposit independent of Allowance
        ///@notice This rule checks that the value returned by the previewDeposit function is independent of allowance that the contract might have for transferring assets from any user. The value retunred is the same regardless of the specified asset amount being more than, equal to or less than the allowance.
        rule previewDepositIndependentOfAllowanceApprove()
        {
            env e1;
            env e2;
            env e3;
            env e4;
            env e5;
            address user;
            uint256 ATokAllowance1 = _AToken.allowance(currentContract, user);
            uint256 assets1;
            require assets1 < ATokAllowance1;
            uint256 previewShares1 = previewDeposit(e1, assets1);

            uint256 amount1;
            _AToken.approve(e2, currentContract, amount1);
            
            uint256 ATokAllowance2 = _AToken.allowance(currentContract, user);
            require assets1 == ATokAllowance2;
            uint256 previewShares2 = previewDeposit(e3, assets1);
            
            uint256 amount2;
            _AToken.approve(e4, currentContract, amount2);
            
            uint256 ATokAllowance3 = _AToken.allowance(currentContract, user);
            require assets1 > ATokAllowance3;
            uint256 previewShares3 = previewDeposit(e5, assets1);

            assert previewShares1 == previewShares2,"previewDeposit should not change regardless of assets > or = allowance";
            assert previewShares2 == previewShares3,"previewDeposit should not change regardless of assets < or = allowance";
        }

    /****************************
    *        previewMint        *
    *****************************/

        /***
        * rule to check the following for the previewMint function:
        * _1. MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call in the same transaction. 
        * I.e. mint should return the same or fewer assets as previewMint if called in the same transaction.
        */
        // STATUS: Verified, that the amount returned by previewMint is exactly equal to that returned by the deposit function.
        //         This is a stronger property than the one required by the EIP.
        // https://vaas-stg.certora.com/output/11775/97ed98809a464668b0bfbfb6f6a6277b/?anonymousKey=e8f91f54cebea2f42d809068cf55511670b817d4
        ///@title previewMint returns the right value
        ///@notice EIP4626 dictates that previewMint must return as close to and no more than the exact amount of assets that would be deposited in a mint call in the same transaction. The previewMint function in staticAToken contract returns a value exactly equal to that returned by the mint function.
        rule previewMintAmountCheck(env e){
            uint256 shares;
            address receiver;
            uint256 previewAssets;
            uint256 assets;

            previewAssets = previewMint(shares);
            assets = mint(e, shares, receiver);
            assert previewAssets == assets,"preview should be equal to actual";
        }


        // The EIP4626 spec requires that the previewMint function must not account for mint limits like those returned from maxMint 
        // and should always act as though the mint would be accepted, regardless whether the user has approved the contract to transfer
        // the specified amount of assets

        // The following rule checks that the previewMint returned value is independent of allowance of assets. The value returned by 
        // previewMind under three conditions a. amount < allowance from any user b. amount = allowance from any user c. amount > allowance
        // from any user. The returned value is the same in all cases thus making it independent of the allowance from any user 
        // STATUS: Verified

        // https://vaas-stg.certora.com/output/11775/937cb9bc984947de98c9bf759b483017/?anonymousKey=db3080cc2ddcf91fe3e7dab4d4a56dad24e6bbce
        ///@title previewMint independent of Allowance
        ///@notice This rule checks that the value returned by the previewMint function is independent of allowance that the contract might have for transferring assets from any user. The value returned is the same regardless of the equivalent asset amount being more than, equal to or less than the allowance.
        rule previewMintIndependentOfAllowance(){
        // allowance of currentContract for asset transfer from msg.sender to   
            address user;
            uint256 ATokAllowance1 = _AToken.allowance(currentContract, user);
            uint256 shares1;
            uint256 assets1;
            uint256 assets2;
            env e1;
            require convertToAssets(e1, shares1) < ATokAllowance1;
            uint256 previewAssets1 = previewMint(shares1);

            env e2;
            address receiver1;
            deposit(e2, assets1, receiver1);
            
            uint256 ATokAllowance2 = _AToken.allowance(currentContract, user);
            env e3;
            require convertToAssets(e3, shares1) == ATokAllowance2;
            uint256 previewAssets2 = previewMint(shares1);
            
            env e4;
            address receiver2;
            deposit(e2, assets2, receiver2); 
            
            env e5;
            uint256 ATokAllowance3 = _AToken.allowance(currentContract, user);
            require convertToAssets(e4, shares1) > ATokAllowance3;
            uint256 previewAssets3 = previewMint(shares1);

            assert previewAssets1 == previewAssets2,"previewMint should not change regardless of C2A(shares) > or = allowance";
            assert previewAssets2 == previewAssets3,"previewMint should not change regardless of C2A(shares) < or = allowance";
        }

    /********************************
    *        previewWithdraw        *
    *********************************/

        /***
        * rule to check the following for the previewWithdraw function:
        * _1. MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw call in the 
        * same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if called in the same transaction
        */
        // STATUS: Verified, that the amount returned by previewWithdraw is exactly equal to that returned by the withdraw function.
        //         This is a stronger property than the one required by the EIP.
        // https://vaas-stg.certora.com/output/11775/444832541b5f4f22ab7373f6de1ee782/?anonymousKey=86856741d701630321afe5bc573fc258bbd99739
        ///@title previewWithdraw returns the right value
        ///@notice EIP4626 dictates that previewWithdraw must return as close to and no more than the exact amount of shares that would be burned in a withdraw call in the same transaction. The previewWithdraw function in staticAToken contract returns a value exactly equal to that returned by the withdraw function.
        rule previewWithdrawAmountCheck(env e){
            uint256 assets;
            address receiver;
            address owner;
            uint256 shares;
            uint256 previewShares;

            previewShares = previewWithdraw(assets);
            shares = withdraw(e, assets, receiver, owner);

            assert previewShares == shares,"preview should be equal to actual shares";
        }

        // The EIP4626 spec requires that the previewWithdraw function must not account for withdrawal limits like those returned 
        // from maxWithdraw and should always act as though the withdrawal would be accepted, regardless of whether or not the user 
        // has enough shares, etc. 
        // This rules checks that the previewWithdraw function return value is independent of any level of maxWithdraw (relative to 
        // the asset amount) for any user

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/50abf537cd134084ab309788a0d4b95a/?anonymousKey=c9cbb863531b85f4a877260997f0acfb770e7e99

        ///@title previewWithdraw independent of maxWithdraw
        ///@notice This rule checks that the value returned by previewWithdraw is independent of the value returned by maxWithdraw.
        rule previewWithdrawIndependentOfMaxWithdraw(env e){
            env e1;
            env e2;
            address user;
            uint256 maxWithdraw1 = maxWithdraw(user);
            uint256 assets1;
            uint256 shares1;
            uint256 shares2;

            require assets1 > maxWithdraw1;
            uint256 previewShares1 = previewWithdraw(assets1);

            mint(e1, shares1, user);

            uint256 maxWithdraw2 = maxWithdraw(user);
            require assets1 ==  maxWithdraw2;
            uint256 previewShares2 = previewWithdraw(assets1);
            
            mint(e2, shares2, user);

            uint256 maxWithdraw3 = maxWithdraw(user);
            require assets1 <  maxWithdraw3;
            uint256 previewShares3 = previewWithdraw(assets1);

            assert previewShares1 == previewShares2 && previewShares2 == previewShares3,"preview withdraw should be independent of allowance";
        }

        // The EIP4626 spec requires that the previewWithdraw function must not account for withdrawal limits like those returned by 
        // maxWithdraw and should always act as though the withdrawal would be accepted, regardless if the user has enough shares, etc.
        // The following two rules checks that the previewWithdraw function is independent of any level of share balance(relative to asset amount) of
        // any user
        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/8e8fd50a3fba4018b924eb6d8764d77f/?anonymousKey=3fee78908151c06e470add0ed2a9f4479f9bea7b

        ///@title previewWithdraw independent of any user's share balance
        ///@notice This rule checks that the value returned by the previewWithdraw function is independent of any user's share balance. The value retunred is the same regardless it being >, = or < any user's balance.
        rule previewWithdrawIndependentOfBalance1(){
            env e1;
            env e2;
            env e3;

            address user;
            uint256 shareBal1 = balanceOf(user);
            uint256 assets1;
            uint256 shares1;
            uint256 shares2;
            
            require assets1 > convertToAssets(e1, shareBal1);//asset amount greater than what the user is entitled to on account of his share balance
            uint256 previewShares1 = previewWithdraw(assets1);

            _mintWrapper(e2, user, shares1);

            uint256 shareBal2 = balanceOf(user);
            require assets1 ==  convertToAssets(e3, shareBal2); //asset amount equal to what the user is entitled to on account of his share balance
            uint256 previewShares2 = previewWithdraw(assets1);

            assert previewShares1 == previewShares2,
            "preview withdraw should be independent of allowance";
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/c686d90f1baf4a77a093d5902125f08f/?anonymousKey=da2ce2f7098c87d89abb767139e689017bd618b1

        rule previewWithdrawIndependentOfBalance2(){
            env e1;
            env e2;
            env e3;

            address user;
            uint256 shareBal1 = balanceOf(user);
            uint256 assets1;
            uint256 shares1;
            uint256 shares2;
            
            require assets1 == convertToAssets(e1, shareBal1);//asset amount greater than what the user is entitled to on account of his share balance
            uint256 previewShares1 = previewWithdraw(assets1);

            _mintWrapper(e2, user, shares1);
            
            uint256 shareBal2 = balanceOf(user);
            require assets1 <  convertToAssets(e3, shareBal2); //asset amount equal to what the user is entitled to on account of his share balance
            uint256 previewShares2 = previewWithdraw(assets1);

            assert previewShares1 == previewShares2,
            "preview withdraw should be independent of allowance";
        }

    /******************************
    *        previewRedeem        *
    *******************************/

        /***
        * rule to check the following for the previewRedeem function:
        * _1. MUST return as CLOSE to and no more than the exact amount of assets that would be withdrawn in a redeem call in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the same transaction.
        */
        // STATUS: Verified, that the amount returned by previewRedeem is exactly equal to that returned by the redeem function.
        //         This is a stronger property than the one required by the EIP.
        // https://vaas-stg.certora.com/output/11775/24e2fe4d485a42618e4e38f0d4376dd2/?anonymousKey=a117a61d3d1dea53fbc875be84292f27af3afd6a

        ///@title previewRedeem returns the right value
        ///@notice EIP4626 dictates that previewRedeem must return as close to and no more than the exact amount of assets that would be returned in a redeem call in the same transaction. The previewRedeem function in staticAToken contract returns a value exactly equal to that returned by the redeem function.
        rule previewRedeemAmountCheck(env e){
            uint256 shares;
            address receiver;
            address owner;
            uint256 previewAssets;
            uint256 assets;
            
            previewAssets = previewRedeem(shares);
            assets = redeem(e, shares, receiver, owner);
            
            assert previewAssets == assets,"preview should the same as the actual assets received";
        }

        // The EIP4626 spec requires that the previewRedeem function must not account for redemption limits like those returned by 
        // the maxRedeem function and should always act as though the redemption would be accepted, regardless if the user has enough 
        // shares, etc.
        // 
        // The following two rules checks that the previewRedeem return value is independent of any level of maxRedeem (relative to the share amount) for any user.

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/e1d9f84456b04e3caa0c4495f3022bb8/?anonymousKey=d82a8ae9fd795f8206f8c117bf5698079c2239cb

        ///@title previewRedeem independent of maxRedeem
        ///@notice This rule checks that the value returned by the previewRedeem function is independent of the value returned by maxRedeem. The value retunred is the same regardless of it being >, = or < the value returned by maxRedeem.
        rule previewRedeemIndependentOfMaxRedeem1(){
            env e1;
            env e2;
            address user;
            uint256 shares1;
            uint256 shares2;

            uint256 maxRedeemableShares1 = maxRedeem(user);
            require shares1 == maxRedeemableShares1;
            uint256 previewAssets1 = previewRedeem(shares1);
            
            _mintWrapper(e1, user, shares2);

            uint256 maxRedeemableShares2 = maxRedeem(user);
            require shares1 < maxRedeemableShares2;
            uint256 previewAssets2 = previewRedeem(shares1);

            assert previewAssets1 == previewAssets2,"previewRedeem should be independent of maxRedeem";
        }

        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/16a4a248207b4ae28d778b0f405a3161/?anonymousKey=5efc898c58a75e7fa35d104b23ea3ef4ffe7ecf3
        rule previewRedeemIndependentOfMaxRedeem2(){
            env e1;
            env e2;
            address user;
            uint256 shares1;
            uint256 shares2;
            
            uint256 maxRedeemableShares1 = maxRedeem(user);
            require shares1 > maxRedeemableShares1;
            uint256 previewAssets1 = previewRedeem(shares1);
            
            _mintWrapper(e1, user, shares2);

            uint256 maxRedeemableShares2 = maxRedeem(user);
            require shares1 == maxRedeemableShares2;
            uint256 previewAssets2 = previewRedeem(shares1);

            assert previewAssets1 == previewAssets2,"previewRedeem should be independent of maxRedeem";
        }

        // The EIP4626 spec requires that the previewRedeem function must not account for redemption limits like those returned by maxRedeem
        //  and should always act as though the redemption would be accepted, regardless of whether the user has enough shares, etc.
        // The following rule checks that the previewRedeem return value is independent of any level of share balance (relative to the redemption 
        // share amount) for any user.
        // STATUS: Verified
        // https://vaas-stg.certora.com/output/11775/de8e4742dbc44945b94e3a9b8e4375ae/?anonymousKey=65bd53e6365d5dd66f76004a80f45de06f088359

        ///@title previewRedeem independent of any user's balance
        ///@notice This rule checks that the value returned by the previewRedeem function is independent of any user's share balance. The value retunred is the same regardless of it being >, = or < any user's balance.
        rule previewRedeemIndependentOfBalance(){
            env e1;
            env e2;
            env e3;
            uint256 shares1;
            uint256 shares2;
            uint256 shares3;
            address user1;
            uint256 balance1 = balanceOf(user1);
            require shares1 > balance1;
            uint256 previewAssets1 = previewRedeem(shares1);

            mint(e1, shares2, user1);
            uint256 balance2 = balanceOf(user1);
            require shares1 == balance2;
            uint256 previewAssets2 = previewRedeem(shares1);
            
            mint(e1, shares3, user1);
            uint256 balance3 = balanceOf(user1);
            require shares1 < balance3;
            uint256 previewAssets3 = previewRedeem(shares1);

            assert previewAssets1 == previewAssets2 && previewAssets2 == previewAssets3,"previewRedeem should be independent of balance";
        }

    /****************************
    *         withdraw         *
    ****************************/

        /***
        * rule to check the following for the withdraw function:
        * 1. SHOULD check msg.sender can spend owner funds, assets needs to be converted to shares and shares should be checked for allowance.
        * 2. MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        */
        // STATUS: VERIFIED
        // violates #2 above. For any asset amount worth less than 1/2 AToken, the function will not withdrawn anything and not revert. EIP 4626 non compliant for assets < 1/2 AToken.
        // For assets amount worth less than 1/2 AToken 0 assets will be withdrawn. Asset amount worth 1/2 AToken and more the final withdrawn amount would be assets +- 1/2AToken.
        // https://vaas-stg.certora.com/output/11775/a2ff16b9d15d405cb11572afd0ea9413/?anonymousKey=2d51005a275559a456558660e33de6870aa19846
        ///@title Allowance and withdrawn amount check for withdraw function
        ///@notice This rules checks that the withdraw function burns shares upto the allowance for the msg.sender and that the assets withdrawn are within the specified asset amount +- 1/2ATokens range
        rule withdrawCheck(env e){
            address owner;
            address receiver;
            uint256 assets;
            
            uint256 allowed = allowance(e, owner, e.msg.sender);
            uint256 balBefore = _AToken.balanceOf(receiver);
            uint256 shareBalBefore = balanceOf(owner);
            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            require e.msg.sender != currentContract;
            require receiver != currentContract;
            require owner != currentContract;
            
            require index >= RAY();
            
            uint256 sharesBurnt = withdraw(e, assets, receiver, owner);

            uint256 balAfter = _AToken.balanceOf(receiver);
            uint256 shareBalAfter = balanceOf(owner);

            // checking for allowance in case msg.sender is not the owner
            assert e.msg.sender != owner => allowed >= sharesBurnt,"msg.sender should have allowane to spend owner's shares";

            // lower bound. First part means atleast 1/2 AToken worth of UL is being deposited
            assert assets * 2 * RAY() >= to_mathint(index) => balAfter - balBefore > assets - index/2*RAY(),
            "withdrawn amount should be no less than 1/2 AToken worth of UL less than the assets amount"; 
            
            //upper bound 
            assert balAfter - balBefore <= assets + index/2*RAY(),
            "withdrawn amount should be no more than 1/2 AToken worth of UL more than the number of assets ";
        }

    /**************************
    *         redeem         *
    **************************/

        /***
        * rule to check the following for the withdraw function:
        * 1. SHOULD check msg.sender can spend owner funds using allowance.
        * 2. MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        */
        // STATUS: VERIFIED
        // https://vaas-stg.certora.com/output/11775/ff8f93d3158f40a5bb27ba35b15e771d/?anonymousKey=c0e02f130ff0d31552c6741d3b1751bda5177bfd
        ///@title allowance and minted share amount check for redeem function
        ///@notice This rules checks that the redeem function burns shares upto the allowance for the msg.sender and that the shares burned are exactly equal to the specified share amount
        rule redeemCheck(env e){
            uint256 shares;
            address receiver;
            address owner;
            uint256 assets;
            mathint allowed = allowance(e, owner, e.msg.sender);
            uint256 balBefore = balanceOf(owner);

            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            require index > RAY();
            require e.msg.sender != currentContract;
            require receiver != currentContract;
            
            assets = redeem(e, shares, receiver, owner);
            
            uint256 balAfter = balanceOf(owner);

            assert e.msg.sender != owner => allowed >= (balBefore - balAfter),"msg.sender should have allowance for transferring owner's shares";
            assert to_mathint(shares) == balBefore - balAfter,"exactly the specified amount of shares must be burnt";
        }

        /***
        * rule to check the following for the withdraw function:
        * 1. SHOULD check msg.sender can spend owner funds using allowance.
        * 2. MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        */
        // STATUS: VERIFIED
        // https://vaas-stg.certora.com/output/11775/ff8f93d3158f40a5bb27ba35b15e771d/?anonymousKey=c0e02f130ff0d31552c6741d3b1751bda5177bfd
        ///@title allowance and minted share amount check for redeem function
        ///@notice This rules checks that the redeem function burns shares upto the allowance for the msg.sender and that the shares burned are exactly equal to the specified share amount
        rule redeemATokensCheck(env e){
            uint256 shares;
            address receiver;
            address owner;
            uint256 assets;
            mathint allowed = allowance(e, owner, e.msg.sender);
            uint256 balBefore = balanceOf(owner);

            uint256 index = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
            require index > RAY();
            require e.msg.sender != currentContract;
            require receiver != currentContract;
            
            assets = redeemATokens(e, shares, receiver, owner);
            
            uint256 balAfter = balanceOf(owner);

            assert e.msg.sender != owner => allowed >= (balBefore - balAfter),"msg.sender should have allowance for transferring owner's shares";
            assert to_mathint(shares) == balBefore - balAfter,"exactly the specified amount of shares must be burnt";
        }

    /*****************************
    *      convertToAssets      *
    *****************************/

        /***
        * rule to check the following for the covertToAssets function:
        * 1. MUST NOT show any variations depending on the caller.
        * 2. MUST round down towards 0.
        */
        // STATUS: VERIFIED
        // https://vaas-stg.certora.com/output/11775/52075caad70145798090e1038b16e6d0/?anonymousKey=b79fa800a2885356277ca6690c723fece38c7b40
        ///@title convert to assets function check
        ///@notice This rule checks that the convertToAssets function will return the same amount for assets for the given number of shares under all conditions and the calculation will always round down.
        rule convertToAssetsCheck(){
            env e1;
            env e2;
            env e3;
            uint256 shares1;
            uint256 shares2;
            storage before  = lastStorage;
            
            mathint assets1         = convertToAssets(e1, shares1)           at before;
            mathint assets2         = convertToAssets(e2, shares1)           at before;
            mathint assets3         = convertToAssets(e2, shares2)           at before;
            mathint combinedAssets  = convertToAssets(e3, require_uint256(shares1 +shares2))  at before;

            // assert !lastReverted,"should not revert except for overflow";
            assert assets1 == assets2,"conversion to assets should be independent of env such as msg.sender";
            assert shares1 + shares2 <= max_uint256 => assets1 + assets3 <= combinedAssets,"conversion should round down and not up";
        }
        
		/// @title Converting amount to shares is properly rounded down
        rule amountConversionRoundedDown(uint256 amount) {
			env e;
            uint256 shares = convertToShares(e, amount);
            assert convertToAssets(e, shares) <= amount, "Too many converted shares";

            /* The next assertion shows that the rounding in `convertToAssets` is tight. This
            * protects the user. For example, a function `convertToAssets` that always returns 
            * zero would have passed the previous assertion, but not the next one.
            */
            assert convertToAssets(e, require_uint256(shares + 1)) >= amount, "Too few converted shares";
        }

        /**
        * @title ConvertToAssets must not revert unless due to integer overflow
        * From EIP4626:
        * > MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
        * We define large input as 10^45. To be precise we need that `shares * rate < 2^256 ~= 10^77`,
        * hence we require that:
        * - `shares < 10^45`
        * - `rate < 10^32`
        */
        rule toAssetsDoesNotRevert(uint256 shares) {
            require shares < 10^45;
            env e;
            require e.msg.value == 0;

            // Prevent revert due to overflow.
            // Roughly speaking ConvertToAssets returns shares * rate() / RAY.
            mathint ray_math = to_mathint(RAY());
            mathint rate_math = to_mathint(rate());
            mathint shares_math = to_mathint(shares);
            require rate_math < 10^32;

            uint256 assets = convertToAssets@withrevert(e, shares);
            bool reverted = lastReverted;

            assert !reverted, "Conversion to assets reverted";
        }

    /*****************************
    *      convertToShares      *
    *****************************/

        /***
        * rule to check the following for the convertToShares function:
        * 1. MUST NOT show any variations depending on the caller.
        * 2. MUST round down towards 0.
        */
        // STATUS: VERIFIED
        // https://vaas-stg.certora.com/output/11775/a75adca8d9914e80bf09bbaeb168f0f8/?anonymousKey=34ac3fe43e28e4722c7d4211af6e3e1077dc3b22
        ///@title convert to shares function check
        ///@notice This rule checks that the convertToShares function will return the same amount for shares for the given number of assets under all conditions and the calculation will always round down.
        rule convertToSharesCheck(){
            env e1;
            env e2;
            env e3;
            uint256 assets1;
            uint256 assets2;
            storage before  = lastStorage;
            
            mathint shares1 = convertToShares(e1, assets1) at before;
            mathint shares2 = convertToShares(e2, assets1) at before;
            mathint shares3 = convertToShares(e2, assets2) at before;
            mathint combinedShares = convertToShares(e3, require_uint256(assets1 + assets2)) at before;

            assert shares1 == shares2,"conversion to shares should be independent of env variables including msg.sender";
            assert shares1 + shares3 <= combinedShares,"conversion should round down and not up";
        }
        
		/// @title Converting shares to amount is properly rounded down
        rule sharesConversionRoundedDown(uint256 shares) {
			env e;
            uint256 amount = convertToAssets(e, shares);
            assert convertToShares(e, amount) <= shares, "Amount converted is too high";

            /* The next assertion shows that the rounding in `convertToShares` is tight.
            * For example, a function `convertToShares` that always returns zero
            * would have passed the previous assertion, but not the next one.
            */
            assert convertToShares(e, require_uint256(amount + 1)) >= shares, "Amount converted is too low";
        }

		/**
        * @title ConvertToShares must not revert except for overflow
        * From EIP4626:
        * > MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
        * We define large input as `10^50`. To be precise, we need that `RAY * assets < 2^256`, since
        * `2^256~=10^77` and `RAY=10^27` we get that `assets < 10^50`.
        * 
        * Note. *We also require that:* **`rate > 0`**.
        */
        rule toSharesDoesNotRevert(uint256 assets) {
            require assets < 10^50;
            env e;
            require e.msg.value == 0;

            // Prevent revert due to overflow.
            // Roughly speaking ConvertToShares returns assets * RAY / rate().
            mathint ray_math = to_mathint(RAY());
            mathint rate_math = to_mathint(rate());
            mathint assets_math = to_mathint(assets);
            require rate_math > 0;

            uint256 shares = convertToShares@withrevert(e, assets);
            bool reverted = lastReverted;

            assert !reverted, "Conversion to shares reverted";
        }

    /************************
    *      maxWithdraw      *
    *************************/

        // maxWithdraw must not revert
        // Nissan remark Aug-2025: this rule doesn't hold due to (a theoretical) possible arithmetical overflow
        // in the functions rayDivRoundUp/Down
        rule maxWithdrawMustntRevert(address user){
        // This assumption subject to correct configuration of the pool, aToken and statAToken.
        // The assumption was ran by and approved by BGD
        require rate() > RAY();
        require rate() <= 100 * RAY();
        maxWithdraw@withrevert(user);
        assert !lastReverted;
        }

        /// @title Ensure `maxWithdraw` conforms to conversion functions
        rule maxWithdrawConversionCompliance(address owner) {
        env e;
        uint256 shares = balanceOf(owner);
        uint256 amountConverted = convertToAssets(e, shares);
        
        assert maxWithdraw(e, owner) <= amountConverted, "Can withdraw more than converted amount";
        }

    /**********************
    *      maxRedeem      *
    ***********************/

        // maxRedeem must not revert
        // Nissan remark Aug-2025: this rule doesn't hold due to (a theoretical) possible arithmetical overflow
        // in the functions rayDivRoundUp/Down
        rule maxRedeemMustntRevert(address user) {
        // This assumption subject to correct configuration of the pool, aToken and statAToken.
        // The assumption was ran by and approved by BGD
        require rate() > RAY();
        require rate() <= 100 * RAY();
        maxRedeem@withrevert(user);
        assert !lastReverted;
        }

        /// @title Ensure `maxRedeem` is not higher than balance
        rule maxRedeemCompliance(address owner) {
        uint256 shares = balanceOf(owner);
        assert maxRedeem(owner) <= shares, "Can redeem more than available shares)";
        }

    /************************
    *       maxDeposit      *
    *************************/

        // maxDeposit must not revert
        // Nissan remark Aug-2025: this rule doesn't hold due to (a theoretical) possible arithmetical overflow
        // in the functions rayDivRoundUp/Down
        rule maxDepositMustntRevert(address user) {
        env e;
        require e.msg.value ==0;
        // This assumption subject to correct configuration of the pool, aToken and statAToken.
        // The assumption was ran by and approved by BGD
        require _AToken.scaledTotalSupply() <= 10^36; // arbitrary extremely large sum of tokens. 10^18 of 18 decimals tokens
        require rate() > RAY();
        require rate() <= 100 * RAY();
        maxDeposit@withrevert(e, user);
        assert !lastReverted;
        }

    /************************
    *       maxMint      *
    *************************/

        // maxMint must not revert
        // Nissan remark Aug-2025: this rule doesn't hold due to (a theoretical) possible arithmetical overflow
        // in the functions rayDivRoundUp/Down
        rule maxMintMustntRevert(address user) {
        env e;
        require e.msg.value ==0;
        // This assumption subject to correct configuration of the pool, aToken and statAToken.
        // The assumption was ran by and approved by BGD
        require rate() > RAY();
        require rate() <= 100 * RAY();
        require _AToken.scaledTotalSupply() <= 10^36; // arbitrary extremely large sum of tokens. 10^18 of 18 decimals tokens
        maxMint@withrevert(e,user);
        assert !lastReverted;
        }

    /*************************
    *       totalAssets      *
    **************************/

        // totalAssets must not revert
        rule totalAssetsMustntRevert(address user){
            // This assumption subject to correct configuration of the pool, aToken and statAToken.
            // The assumption was ran by and approved by BGD
            require rate() > RAY();
            require rate() <= 100 * RAY();
            totalAssets@withrevert();
            assert !lastReverted;
        }

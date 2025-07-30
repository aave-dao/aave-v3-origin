
The property that we prove in this directory is the following solvency invariant (for an arbitrary asset):
         (*)  Atoken.totalSupply() <= VariableDebtToken.totalSupply() + virtual_balance + deficit

Intuitively, the left hand side is the amount that the pool owes to its users, and the right hand 
side is the amount it has (either in hands - the virtual_balance, or what people owe to it - the VariableDebtToken.totalSupply(), or the deficit that need to be covered by Umbrella).

Note that:
1. We actually prove a bit stronger claim. We prove that for every mathint DELTA
   If before the function call it holds that:
        Atoken.totalSupply() <= VariableDebtToken.totalSupply() + virtual_balance + deficit + DELTA
   then it also holds after the function call.
   This is important because for most assets there is a difference (in the live code) between the right and the left
   hand sides of (*), thus we actually prove that this difference can't decrease.

2. The above is proved under the following assumptions:
   a. RAY <= liquidity-index  &&  RAY <= borrow-index. (this should be easy to prove)

3. We deal with each function in a separate file/files. For some functions (repay, repayWithATokens, liquidationCall) we
   dedicate a sub-directory, because the proof is more involved and contains lemmas or case splits. See the README.txt
   files in those directories for more information.

4. Basically we should prove that (*) is preserved not only after a function call, but also for time passing. Time passing
   is indeed relevant because the indexes increase with time, hence the Atoken.totalSupply() and
   VariableDebtToken.totalSupply() that appear in (*) also increase with time.
   Unfortunately we can't prove that in this context. Below we give a short explanation for that.To prove it we
   need to prove the following stronger invariant:
      (**)  Atoken.totalSupply() + accruedToTreasury == VariableDebtToken.totalSupply() + virtual_balance + deficit.
   For more about this see the file src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol. In this file
   the liquidity-rate and the debt-rate are calculated. Those rates determine the growth on the indexes with time,
   and are designed to have the following property:
   Consider 2 timestamps t1<t2. Let:
       delta(Debt) := the difference between VariableDebtToken.totalSupply() at time t2 and t1;
       delta(Atoken) := the difference between Atoken.totalSupply() at time t2 and t1;
       delta(accruedToTreasury) := the difference between accruedToTreasury at time t2 and t1;
    Then the calculations that are done in the above file, and are based on (**), guarantees that
    delta(Debt) = delta(Atoken)+ delta(accruedToTreasury) (and hence that (**) is preserved for "time passing").
    Unfortunately we can't prove that delta(Debt) = delta(Atoken)+delta(accruedToTreasury) holds only by assuming (*).

5. Since some functions of the pool (specifically liquidationCall and repay functions) are very complex and issue time-outs
   we used the following two technique to ease the prover's work:
   (i) Summarize getNormalizedIncome(), and getNormalizedDebt() to return constant values. That means that 
       we assume that all the calls to these 2 functions returns the same value (each function has its own value),
       and the call can be either:
       - Before we call to the checked pool function (like repay()). For example in the calculation on atoken.totalSupply().
       - During the execution of the pool function (say the repay()).
       - After the call to the pool function, for example when we calculate atoken.totalSupply().

       Obviously we need to prove that this assertion is valid, and we indeed do it (in the files named lemma-*.spec)
       Note that in the case of the function liquidationCall(), this summarization is a bit more complex, since
       getNormalizedIncome() for example is called with respect to 2 different assets: the debt asset and the collateral asset.
       Hence in the summarization we have to distinguish between these 2 cases and we do it by looking at the address of the asset.

   (ii) Hook functions:
        Assume that we are verifying the solvency property of the function repayWithATokens(), and we want to add some assertions
        right after a (specific) call to the burn() function. To achieve that, we munged the solidity code by declaring
        a new internal function and calling it immediately after the call to burn(). Something like:

        atoken.burn(.....);
        /* HOOK */ HOOK_repay_after_burn_ATOKEN(...); // this is the call we add.

        In the CVL code we summarize the function by adding to the method block something like:

        function BorrowLogic.HOOK_repay_after_burn_ATOKEN(DataTypes.ReserveCache memory reserveCache)
           internal with (env e) => HOOK_repay_after_burn_ATOKEN_CVL(e, reserveCache);

        and now, in the CVL-function HOOK_repay_after_burn_ATOKEN_CVL(..) we may put any assertion we want and it is guaranteed
        that the prover will prove this assertion right after that call to burn().

        Why should we do such a thing ?
        When we run with the flag --multi_assert_check, each assert statement is treated separately while all the previous
        assertions (assuming they were already proved) are transformed into a requirement statement. It turned out that these "new"
        requirements can help the prover to avoid time-outs.

        We use this technique in the function repayWithATokens(), and very extensively in the function liquidationCall().

6. 

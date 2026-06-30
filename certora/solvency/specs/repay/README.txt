
We prove the solvency property for the repay() function (see also the README.txt file in spec/ directory).

We have 2 files here: main.spec, where we prove that main property, and lemma.spec where we prove several
assumptions that are done in the file main.spec. The assumptions are:
1. The scaled-total-supply of variable-debt != 0. And indeed, we prove in lemma.spec that if it is 0, that
   call to repay reverts.
2. We summarize the functions getNormalizedIncome(), and getNormalizedDebt() to the constants values
   LIQUIDITY_INDEX, and DEBT_INDEX (respectively). And indeed in the file lemma.spec we justify this
   assumption in the rule repay__index_unchanged(). Note that this assumption is crucial in order to
   avoid time-outs.
   

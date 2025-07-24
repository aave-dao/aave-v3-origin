
We prove the solvency property for the repayWithATokens() function (see also the README.txt file in spec/ directory).

We have 2 files here: main.spec, where we prove that main property, and lemma.spec where we prove an 
assumption that we do in the file main.spec. The assumption is:
The scaled-total-supply of variable-debt != 0. And indeed, we prove in lemma.spec that if it is 0, that
call to repay reverts.

NOTE:
We use in this spec the "HOOK technique" that is mentioned in spec/README.txt file (see there in 5-(ii)).




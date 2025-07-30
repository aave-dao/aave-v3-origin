
We prove the solvency property for the liquidationCall() function (see also the README.txt file in spec/ directory).

Since the liquidationCall() function involves 2 assets, the DEBT-asset (DBTasset) and the COLATERAL-asset (COLasset),
we break our proof to the following several cases:
(1) Assuming DBTasset != COLasset and prove the solvency property for the DBTasset.
    See files:
    main-DBTasset.spec, lemma-DBTasset.spec.
(2) Assuming DBTasset != COLasset and prove the solvency property for the COLasset.
    See files:
    main-COLasset.spec, main-COLasset-totSUP0.spec, lemma-COLasset.spec, lemma-COLasset-totSUP0.spec.
(3) Assuming DBTasset == COLasset and prove the solvency property for that asset.
    main-SAMEasset.spec, lemma-SAMEasset.spec.

Note: All the files named main-*.spec are for the main property (the solvency), while in the lemma-*.spec
we prove assumption that we use in the main-* files.

The major assumptions/techniques that we use here are:
1. We summarize the functions getNormalizedIncome(), and getNormalizedDebt() to return constant values.
   See 5-(i) in the file spec/README.txt for more about it.
2. We use A-LOT the "HOOK technique". See 5-(ii) in spec/README.txt file.
3. We summarize the internal function _burnBadDebt() in a way that it preserves solvency. We prove that this
   is indeed the case in files: burnBadDebt-assetINloop.spec, burnBadDebt-assetNOTINloop.spec.

   

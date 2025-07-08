import "base_token_v3.spec";

/*==============================================================================================
  In this file we prove that the CVL's version of rayMul and rayDiv are indeed correct.
  We need it especially for the rules in index_EQ_1.spec file.
  =============================================================================================*/

methods {
  function rayMul_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDiv_WRP(uint256 a, uint256 b) external returns (uint256) envfree;
}


rule rayMulCVL_rayDivCVL_correctness() {
  uint256 a;
  uint256 b;

  assert rayMul_WRP(a,b)==rayMulCVL(a,b);
  assert rayDiv_WRP(a,b)==rayDivCVL(a,b);
}




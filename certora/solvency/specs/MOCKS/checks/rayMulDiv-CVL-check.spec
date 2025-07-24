import "../rayMulDiv-CVL.spec";


methods {
  function rayMul(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayMulFloor(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayMulCeil(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDiv(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDivFloor(uint256 a, uint256 b) external returns (uint256) envfree;
  function rayDivCeil(uint256 a, uint256 b) external returns (uint256) envfree;
}


rule rayMulCVLCorrectness(uint x, uint y) {
  uint solidity = rayMul(x,y);
  uint cvl_precise = rayMulCVLPrecise(x, y);
  uint cvl_abstract = rayMulCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}

rule rayMulFloorCVLCorrectness(uint x, uint y) {
  uint solidity = rayMulFloor(x,y);
  uint cvl_precise = rayMulFloorCVLPrecise(x, y);
  uint cvl_abstract = rayMulFloorCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}

rule rayMulCeilCVLCorrectness(uint x, uint y) {
  uint solidity = rayMulCeil(x,y);
  uint cvl_precise = rayMulCeilCVLPrecise(x, y);
  uint cvl_abstract = rayMulCeilCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}


rule rayDivCVLCorrectness(uint x, uint y) {
  uint solidity = rayDiv(x,y);
  uint cvl_precise = rayDivCVLPrecise(x, y);
  uint cvl_abstract = rayDivCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}

rule rayDivFloorCVLCorrectness(uint x, uint y) {
  uint solidity = rayDivFloor(x,y);
  uint cvl_precise = rayDivFloorCVLPrecise(x, y);
  uint cvl_abstract = rayDivFloorCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}

rule rayDivCeilCVLCorrectness(uint x, uint y) {
  uint solidity = rayDivCeil(x,y);
  uint cvl_precise = rayDivCeilCVLPrecise(x, y);
  uint cvl_abstract = rayDivCeilCVLAbstract(x, y);
  assert solidity == cvl_precise;
  assert cvl_precise == cvl_abstract;
}





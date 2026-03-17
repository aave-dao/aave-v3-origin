import "Math/CVLMath.spec";

/* Math utils */
function rayMulCVL(uint x, uint y) returns uint256 {
    return mulDivUpAbstractPlus(x, y, RAY());
}

function rayDivCVL(uint x, uint y) returns uint256 {
    return mulDivUpAbstractPlus(x, RAY(), y);
}

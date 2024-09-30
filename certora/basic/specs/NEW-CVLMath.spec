/******************************************
----------- CVL Math Library --------------
*******************************************/

// A restriction on the value of w = x * y / z
// The ratio between x (or y) and z is a rational number a/b or b/a.
// Important : do not set a = 0 or b = 0.
// Note: constRatio(x,y,z,a,b,w) <=> constRatio(x,y,z,b,a,w)
definition constRatio(uint256 x, uint256 y, uint256 z, uint256 a, uint256 b, uint256 w) returns bool =
  ( a * x == b * z && to_mathint(w) == (b * y) / a ) ||
  ( b * x == a * z && to_mathint(w) == (a * y) / b ) ||
  ( a * y == b * z && to_mathint(w) == (b * x) / a ) ||
  ( b * y == a * z && to_mathint(w) == (a * x) / b );

// A restriction on the value of w = x * y / z
// The division quotient between x (or y) and z is an integer q or 1/q.
// Important : do not set q=0
definition constQuotient(uint256 x, uint256 y, uint256 z, uint256 q, uint256 w) returns bool =
  ( to_mathint(x) == q * z && to_mathint(w) == q * y ) ||
  ( q * x == to_mathint(z) && to_mathint(w) == y / q ) ||
  ( to_mathint(y) == q * z && to_mathint(w) == q * x ) ||
  ( q * y == to_mathint(z) && to_mathint(w) == x / q );

/// Equivalent to the one above, but with implication
definition constQuotientImply(uint256 x, uint256 y, uint256 z, uint256 q, uint256 w) returns bool =
  ( to_mathint(x) == q * z => to_mathint(w) == q * y ) &&
  ( q * x == to_mathint(z) => to_mathint(w) == y / q ) &&
  ( to_mathint(y) == q * z => to_mathint(w) == q * x ) &&
  ( q * y == to_mathint(z) => to_mathint(w) == x / q );

definition ONE18() returns uint256 = 1000000000000000000;
definition RAY() returns uint256 = 10^27;

definition _monotonicallyIncreasing(uint256 x, uint256 y, uint256 fx, uint256 fy) returns bool =
  (x > y => fx >= fy);

definition _monotonicallyDecreasing(uint256 x, uint256 y, uint256 fx, uint256 fy) returns bool =
  (x > y => fx <= fy);

definition abs(mathint x) returns mathint =
  x >= 0 ? x : 0 - x;

definition min(mathint x, mathint y) returns mathint =
  x > y ? y : x;

definition max(mathint x, mathint y) returns mathint =
  x > y ? x : y;

/// Returns whether y is equal to x up to error bound of 'err' (18 decs).
/// e.g. 10% relative error => err = 1e17
definition relativeErrorBound(mathint x, mathint y, mathint err) returns bool =
  (x != 0
    ? abs(x - y) * ONE18() <= abs(x) * err
    : abs(y) <= err);

/// Axiom for a weighted average of the form WA = (x * y) / (y + z)
/// This is valid as long as z + y > 0 => make certain of that condition in the use of this definition.
definition weightedAverage(mathint x, mathint y, mathint z, mathint WA) returns bool =
  ((x > 0 && y > 0) => (WA >= 0 && WA <= x))
  &&
  ((x < 0 && y > 0) => (WA <= 0 && WA >= x))
  &&
  ((x > 0 && y < 0) => (WA <= 0 && WA - x <= 0))
  &&
  ((x < 0 && y < 0) => (WA >= 0 && WA + x <= 0))
  &&
  ((x == 0 || y == 0) => (WA == 0));


function mulDivDownAbstract(uint256 x, uint256 y, uint256 z) returns uint256 {
  require z !=0;
  uint256 xy = require_uint256(x * y);
  uint256 res;
  mathint rem;
  require z * res + rem == to_mathint(xy);
  require rem < to_mathint(z);
  return res;
}

function mulDivDownAbstractPlus(uint256 x, uint256 y, uint256 z) returns uint256 {
  uint256 res;
  require z != 0;
  uint256 xy = require_uint256(x * y);
  uint256 fz = require_uint256(res * z);

  require xy >= fz;
  require fz + z > to_mathint(xy);
  return res;
}

function mulDivUpAbstractPlus(uint256 x, uint256 y, uint256 z) returns uint256 {
  uint256 res;
  require z != 0;
  uint256 xy = require_uint256(x * y);
  uint256 fz = require_uint256(res * z);
  require xy >= fz;
  require fz + z > to_mathint(xy);

  if (xy == fz) {
    return res;
  }
  return require_uint256(res + 1);
}

function mulDownWad(uint256 x, uint256 y) returns uint256 {
  return mulDivDownAbstractPlus(x, y, ONE18());
}

function mulUpWad(uint256 x, uint256 y) returns uint256 {
  return mulDivUpAbstractPlus(x, y, ONE18());
}

function divDownWad(uint256 x, uint256 y) returns uint256 {
  return mulDivDownAbstractPlus(x, ONE18(), y);
}

function divUpWad(uint256 x, uint256 y) returns uint256 {
  return mulDivUpAbstractPlus(x, ONE18(), y);
}

function discreteQuotientMulDiv(uint256 x, uint256 y, uint256 z) returns uint256 {
  uint256 res;
  require z != 0 && noOverFlowMul(x, y);
  // Discrete quotients:
  require(
    ((x ==0 || y ==0) && res == 0) ||
    (x == z && res == y) ||
    (y == z && res == x) ||
    constQuotient(x, y, z, 2, res) || // Division quotient is 1/2 or 2
    constQuotient(x, y, z, 5, res) || // Division quotient is 1/5 or 5
    constQuotient(x, y, z, 100, res) // Division quotient is 1/100 or 100
  );
  return res;
}

function discreteRatioMulDiv(uint256 x, uint256 y, uint256 z) returns uint256 {
  uint256 res;
  require z != 0 && noOverFlowMul(x, y);
  // Discrete ratios:
  require(
    ((x ==0 || y ==0) && res == 0) ||
    (x == z && res == y) ||
    (y == z && res == x) ||
    constRatio(x, y, z, 2, 1, res) || // f = 2*x or f = x/2 (same for y)
    constRatio(x, y, z, 5, 1, res) || // f = 5*x or f = x/5 (same for y)
    constRatio(x, y, z, 2, 3, res) || // f = 2*x/3 or f = 3*x/2 (same for y)
    constRatio(x, y, z, 2, 7, res)    // f = 2*x/7 or f = 7*x/2 (same for y)
  );
  return res;
}

function noOverFlowMul(uint256 x, uint256 y) returns bool {
  return x * y <= max_uint;
}

/// @doc Ghost power function that incorporates mathematical pure x^y axioms.
/// @warning Some of these axioms might be false, depending on the Solidity implementation
/// The user must bear in mind that equality-like axioms can be violated because of rounding errors.
ghost _ghostPow(uint256, uint256) returns uint256 {
  /// x^0 = 1
  axiom forall uint256 x. _ghostPow(x, 0) == ONE18();
  /// 0^x = 1
  axiom forall uint256 y. _ghostPow(0, y) == 0;
  /// x^1 = x
  axiom forall uint256 x. _ghostPow(x, ONE18()) == x;
  /// 1^y = 1
  axiom forall uint256 y. _ghostPow(ONE18(), y) == ONE18();

  /// I. x > 1 && y1 > y2 => x^y1 > x^y2
  /// II. x < 1 && y1 > y2 => x^y1 < x^y2
  axiom forall uint256 x. forall uint256 y1. forall uint256 y2.
    x >= ONE18() && y1 > y2 => _ghostPow(x, y1) >= _ghostPow(x, y2);
  axiom forall uint256 x. forall uint256 y1. forall uint256 y2.
    x < ONE18() && y1 > y2 => (_ghostPow(x, y1) <= _ghostPow(x, y2) && _ghostPow(x,y2) <= ONE18());
  axiom forall uint256 x. forall uint256 y.
    x < ONE18() && y > ONE18() => (_ghostPow(x, y) <= x);
  axiom forall uint256 x. forall uint256 y.
    x < ONE18() && y <= ONE18() => (_ghostPow(x, y) >= x);
  axiom forall uint256 x. forall uint256 y.
    x >= ONE18() && y > ONE18() => (_ghostPow(x, y) >= x);
  axiom forall uint256 x. forall uint256 y.
    x >= ONE18() && y <= ONE18() => (_ghostPow(x, y) <= x);
  /// x1 > x2 && y > 0 => x1^y > x2^y
  axiom forall uint256 x1. forall uint256 x2. forall uint256 y.
    x1 > x2 => _ghostPow(x1, y) >= _ghostPow(x2, y);
}

function CVLPow(uint256 x, uint256 y) returns uint256 {
  if (y == 0) {return ONE18();}
  if (x == 0) {return 0;}
  return _ghostPow(x, y);
}

function CVLSqrt(uint256 x) returns uint256 {
  mathint SQRT;
  require SQRT*SQRT <= to_mathint(x) && (SQRT + 1)*(SQRT + 1) > to_mathint(x);
  return require_uint256(SQRT);
}

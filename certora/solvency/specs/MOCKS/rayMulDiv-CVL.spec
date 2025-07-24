




//*********************************************************************************************
// To change the rayMul / rayDiv of the system, change the following functions
//*********************************************************************************************

function rayMulCVL(uint x, uint y) returns uint256      {return rayMulCVLPrecise(x,y);}
function rayMulFloorCVL(uint x, uint y) returns uint256 {return rayMulFloorCVLPrecise(x,y);}
function rayMulCeilCVL(uint x, uint y) returns uint256  {return rayMulCeilCVLPrecise(x,y);}
function rayDivCVL(uint x, uint y) returns uint256      {return rayDivCVLPrecise(x,y);}
function rayDivFloorCVL(uint x, uint y) returns uint256 {return rayDivFloorCVLPrecise(x,y);}
function rayDivCeilCVL(uint x, uint y) returns uint256  {return rayDivCeilCVLPrecise(x,y);}

/*
function rayMulCVL(uint x, uint y) returns uint256      {return rayMulCVLAbstract(x,y);}
function rayMulFloorCVL(uint x, uint y) returns uint256 {return rayMulFloorCVLAbstract(x,y);}
function rayMulCeilCVL(uint x, uint y) returns uint256  {return rayMulCeilCVLAbstract(x,y);}
function rayDivCVL(uint x, uint y) returns uint256      {return rayDivCVLAbstract(x,y);}
function rayDivFloorCVL(uint x, uint y) returns uint256 {return rayDivFloorCVLAbstract(x,y);}
function rayDivCeilCVL(uint x, uint y) returns uint256  {return rayDivCeilCVLAbstract(x,y);}
*/









//*********************************************************************************************
// RayMul / RayDiv
//*********************************************************************************************
definition RAY() returns uint256 = 10^27;

function rayMulCVLPrecise(uint x, uint y) returns uint256 {
  return require_uint256((x*y + RAY()/2) / RAY());
}

function rayMulFloorCVLPrecise(uint x, uint y) returns uint256 {
  return require_uint256((x*y) / RAY());
}

function rayMulCeilCVLPrecise(uint x, uint y) returns uint256 {
  bool add1 = (x*y) % RAY() != 0;
  return require_uint256((x*y) / RAY() + (add1 ? 1 : 0));
}

function rayDivCVLPrecise(uint x, uint y) returns uint256 {
  require y != 0;
  return require_uint256((x*RAY() + y/2)/y);
}

function rayDivFloorCVLPrecise(uint x, uint y) returns uint256 {
  require y != 0;
  return require_uint256((x*RAY())/y);
}

function rayDivCeilCVLPrecise(uint x, uint y) returns uint256 {
  require y != 0;

  bool add1 = (x*RAY()) % y != 0;
  return require_uint256( (x*RAY())/y + (add1 ? 1 : 0) );
}




function rayMulCVLAbstract(uint x, uint y) returns uint256 {
  //return require_uint256((x*y + RAY()/2) / RAY());
  uint256 ret;
  require ret*RAY() <= x*y + RAY()/2  &&  x*y + RAY()/2 < ret*RAY() + RAY();
  return ret;
}

function rayMulFloorCVLAbstract(uint x, uint y) returns uint256 {
  //  return require_uint256((x*y) / RAY());
  uint256 ret;
  require ret*RAY() <= x*y  &&  x*y < ret*RAY() + RAY();
  return ret;
}

function rayMulCeilCVLAbstract(uint x, uint y) returns uint256 {
  uint256 ret;
  require (ret-1)*RAY() < x*y   &&  x*y <= ret*RAY();
  return ret;
}

function rayDivCVLAbstract(uint x, uint y) returns uint256 {
  require y != 0;

  uint256 ret;
  require  y*ret <= x*RAY() + y/2  &&  x*RAY() + y/2 < y*ret+y;
  return ret;
}

function rayDivFloorCVLAbstract(uint x, uint y) returns uint256 {
  require y != 0;

  uint256 ret;
  require y*ret <= x*RAY()  &&  x*RAY() < y*ret+y;
  return ret;
}

function rayDivCeilCVLAbstract(uint x, uint y) returns uint256 {
  require y != 0;

  uint256 ret;
  require y*(ret-1) < x*RAY()  &&  x*RAY() <= y*ret;
  return ret;
}


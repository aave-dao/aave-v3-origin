




//*********************************************************************************************
// To change the rayMul / rayDiv of the system, change the following functions
//*********************************************************************************************

function rayMulCVL(uint x, uint y) returns uint256      {return rayMulCVLPrecise(x,y);}
function rayMulFloorCVL(uint x, uint y) returns uint256 {return rayMulFloorCVLPrecise(x,y);}
function rayMulCeilCVL(uint x, uint y) returns uint256  {return rayMulCeilCVLPrecise(x,y);}
function rayDivCVL(uint x, uint y) returns uint256      {return rayDivCVLPrecise(x,y);}
function rayDivFloorCVL(uint x, uint y) returns uint256 {return rayDivFloorCVLPrecise(x,y);}
function rayDivCeilCVL(uint x, uint y) returns uint256  {return rayDivCeilCVLPrecise(x,y);}

function percentMulCVL(uint256 value, uint256 percentage) returns uint256 {return percentMulCVLPrecise(value,percentage);}
function percentMulCeilCVL(uint256 value, uint256 percentage) returns uint256 {return percentMulCeilCVLPrecise(value,percentage);}
function percentMulFloorCVL(uint256 value, uint256 percentage) returns uint256 {return percentMulFloorCVLPrecise(value,percentage);}

function percentDivCVL(uint256 value, uint256 percentage) returns uint256 {return percentDivCVLPrecise(value,percentage);}
function percentDivCeilCVL(uint256 value, uint256 percentage) returns uint256 {return percentDivCeilCVLPrecise(value,percentage);}
function percentDivFloorCVL(uint256 value, uint256 percentage) returns uint256 {return percentDivFloorCVLPrecise(value,percentage);}



  
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




definition PERCENTAGE_FACTOR() returns uint256 = 10^4;   //10,000
definition HALF_PERCENTAGE_FACTOR() returns uint256 = 5*10^3; //5,000



// retrun:  div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR);
function percentMulCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  ret = require_uint256( (value*percentage + HALF_PERCENTAGE_FACTOR()) / PERCENTAGE_FACTOR()) ;
  return ret;
}

function percentMulCeilCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  bool add1 = (value*percentage) % PERCENTAGE_FACTOR() != 0;
  ret = require_uint256 ((value * percentage) / PERCENTAGE_FACTOR() + (add1 ? 1 : 0));
  return ret;
}

function percentMulFloorCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  ret = require_uint256 ((value * percentage) / PERCENTAGE_FACTOR());
  return ret;
}




//      result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)

function percentDivCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  ret = require_uint256 ((value*PERCENTAGE_FACTOR() + percentage/2) / percentage);
  return ret;
}

//  let val := mul(value, PERCENTAGE_FACTOR)
//  result := add(div(val, percentage), iszero(iszero(mod(val, percentage))))
function percentDivCeilCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  bool add1 = (value*PERCENTAGE_FACTOR()) % percentage != 0;
  ret = require_uint256 ((value*PERCENTAGE_FACTOR()) / percentage + (add1 ? 1 : 0));
  return ret;
}


function percentDivFloorCVLPrecise(uint256 value, uint256 percentage) returns uint256 {
  uint256 ret;
  ret = require_uint256 ((value*PERCENTAGE_FACTOR()) / percentage);
  return ret;
}



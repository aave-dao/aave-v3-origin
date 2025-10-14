
import "../MOCKS/rayMulDiv-CVL.spec";


methods {
  function _.ADDRESSES_PROVIDER() external => NONDET; // expect address

  function getReserveDataExtended(address) external returns (DataTypes.ReserveData memory) envfree;
  function getReserveAddressById(uint16 id) external returns (address) envfree;
  function getReservesList() external returns (address[]) envfree;
    
  function _.rayMul(uint256 a, uint256 b) external => rayMulCVL(a,b) expect uint256;
  function _.rayMulFloor(uint256 a, uint256 b) external => rayMulFloorCVL(a,b) expect uint256;
  function _.rayMulCeil(uint256 a, uint256 b) external => rayMulCeilCVL(a,b) expect uint256;
  function _.rayDiv(uint256 a, uint256 b) external => rayDivCVL(a,b) expect uint256;
  function _.rayDivFloor(uint256 a, uint256 b) external => rayDivFloorCVL(a,b) expect uint256;
  function _.rayDivCeil(uint256 a, uint256 b) external => rayDivCeilCVL(a,b) expect uint256;

  function _.rayMul(uint256 a, uint256 b) internal => rayMulCVL(a,b) expect uint256;
  function _.rayMulFloor(uint256 a, uint256 b) internal => rayMulFloorCVL(a,b) expect uint256;
  function _.rayMulCeil(uint256 a, uint256 b) internal => rayMulCeilCVL(a,b) expect uint256;
  function _.rayDiv(uint256 a, uint256 b) internal => rayDivCVL(a,b) expect uint256;
  function _.rayDivFloor(uint256 a, uint256 b) internal => rayDivFloorCVL(a,b) expect uint256;
  function _.rayDivCeil(uint256 a, uint256 b) internal => rayDivCeilCVL(a,b) expect uint256;
}





function isVirtualAccActive(uint256 data) returns bool {
  uint mask = 0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  return (data & ~mask) != 0;
}

function init_state() {
  // based on aTokensAreNotUnderlyings
  require forall address a. 
    a == 0 // nothing-token
    || aTokenToUnderlying[a] == 0 // underlying
    || aTokenToUnderlying[aTokenToUnderlying[a]] == 0 // aTokens map to underlyings which map to 0
    ;
  // aTokens have the AToken sort, VariableDebtTokens have the VariableDebt sort, etc...
  require forall address a. tokenToSort[currentContract._reserves[a].aTokenAddress] == AToken_token();
  require forall address a. tokenToSort[currentContract._reserves[a].variableDebtTokenAddress] == VariableDebtToken_token();
}

function tokens_addresses_limitations(address atoken, address variable, address asset) {
  //  require atoken==10; require variable==11; require asset==100;
  //  require weth!=10 && weth!=11 && weth!=12;

  require asset != 0;
  require atoken != variable && atoken != asset;
  require variable != asset;

  require tokenToSort[asset] == VanillaERC20_token();
  // The asset that current rule deals with. It is used in summarization CVL-functions, and other places.
  // See for example _accrueToTreasuryCVL().
  ASSET = asset;
}


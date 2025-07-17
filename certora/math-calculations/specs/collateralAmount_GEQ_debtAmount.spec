import "MOCKS/rayMulDiv-CVL.spec";


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

  function _.percentMul(uint256 a, uint256 b) internal => percentMulCVL(a,b) expect uint256;
  function _.percentMulCeil(uint256 a, uint256 b) internal => percentMulCeilCVL(a,b) expect uint256;

  function _.percentDiv(uint256 a, uint256 b) internal => percentDivCVL(a,b) expect uint256;
  function _.percentDivCeil(uint256 a, uint256 b) internal => percentDivCeilCVL(a,b) expect uint256;
  function _.percentDivFloor(uint256 a, uint256 b) internal => percentDivFloorCVL(a,b) expect uint256;
}



methods {
  function ReserveConfiguration.getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal returns (uint256) => PROTOCOL_FEE;
}

persistent ghost uint256 PROTOCOL_FEE {
  axiom PROTOCOL_FEE <= 65535;
}


rule collateralAmount_GEQ_debtAmount_same_units_prices() {
  env e;

  DataTypes.ReserveConfigurationMap collateralReserveConfiguration;
  uint256 __collateralAssetPrice; uint256 __collateralAssetUnit; uint256 __debtAssetPrice; uint256 __debtAssetUnit;
  uint256 __debtToCover; uint256 __borrowerCollateralBalance; uint256 __liquidationBonus;

  //require __debtAssetUnit == 1000;  require __collateralAssetUnit == 1000;
  //require __debtAssetPrice == 10^8; require __collateralAssetPrice == 10^8;
  require 10000 <= __liquidationBonus  &&  __liquidationBonus <= 60000;

  require __debtAssetPrice == __collateralAssetPrice; require __debtAssetUnit == __collateralAssetUnit;

  require __debtAssetPrice != 0  &&  __collateralAssetPrice != 0; require __debtAssetUnit !=0  &&  __collateralAssetUnit != 0;

  //  require __liquidationBonus == 10100;
  require PROTOCOL_FEE <= 10000;
  
  uint256 collateralAmount; uint256 debtAmountNeeded; uint256 liquidationProtocolFee; uint256 collateralToLiquidateInBaseCurrency;
  (collateralAmount, debtAmountNeeded, liquidationProtocolFee, collateralToLiquidateInBaseCurrency) = 
  WRP_calculateAvailableCollateralToLiquidate(e,
                                              collateralReserveConfiguration,
                                              __collateralAssetPrice,
                                              __collateralAssetUnit,
                                              __debtAssetPrice,
                                              __debtAssetUnit,
                                              __debtToCover,
                                              __borrowerCollateralBalance,
                                              __liquidationBonus
                                             );


  assert debtAmountNeeded <= collateralAmount ;
}



rule collateralAmount_GEQ_debtAmount_general() {
  env e;

  DataTypes.ReserveConfigurationMap collateralReserveConfiguration;
  uint256 __collateralAssetPrice; uint256 __collateralAssetUnit; uint256 __debtAssetPrice; uint256 __debtAssetUnit;
  uint256 __debtToCover; uint256 __borrowerCollateralBalance; uint256 __liquidationBonus;
  require __debtToCover > 0;

  require 10000 <= __liquidationBonus  &&  __liquidationBonus <= 70000;

  //  require __debtAssetPrice != 0  &&  __collateralAssetPrice != 0; require __debtAssetUnit !=0  &&  __collateralAssetUnit != 0;

  require PROTOCOL_FEE <= 10000;
  
  uint256 collateralAmount; uint256 debtAmountNeeded; uint256 liquidationProtocolFee; uint256 collateralToLiquidateInBaseCurrency;
  (collateralAmount, debtAmountNeeded, liquidationProtocolFee, collateralToLiquidateInBaseCurrency) = 
  WRP_calculateAvailableCollateralToLiquidate(e,
                                              collateralReserveConfiguration,
                                              __collateralAssetPrice, __collateralAssetUnit,
                                              __debtAssetPrice, __debtAssetUnit,
                                              __debtToCover, __borrowerCollateralBalance,
                                              __liquidationBonus
                                             );


  assert debtAmountNeeded * __debtAssetPrice / __debtAssetUnit <= collateralAmount * __collateralAssetPrice / __collateralAssetUnit;
}


// 01234567890123456789012345678
// 1000000000000000000000000000
// 1240000000000000000
// 500000000000000000


import {MathUtils} from '../munged/src/contracts/protocol/libraries/math/MathUtils.sol';
import {FlashLoanLogic} from '../munged/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol';
import {DataTypes} from '../munged/src/contracts/protocol/libraries/types/DataTypes.sol';
import {WadRayMath} from '../munged/src/contracts/protocol/libraries/math/WadRayMath.sol';

contract Utilities {
  function havocAll() external {
    (bool success, ) = address(0xdeadbeef).call(abi.encodeWithSelector(0x12345678));
    require(success);
  }

  function justRevert() external {
    revert();
  }

  function nop() external {}

  function SECONDS_PER_YEAR() external view returns (uint256) {
    return MathUtils.SECONDS_PER_YEAR;
  }

  function rayMul(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayMul(a, b);
  }

  function rayMulFloor(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayMulFloor(a, b);
  }

  function rayMulCeil(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayMulCeil(a, b);
  }

  function rayDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayDiv(a, b);
  }

  function rayDivFloor(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayDivFloor(a, b);
  }

  function rayDivCeil(uint256 a, uint256 b) external pure returns (uint256 c) {
    return WadRayMath.rayDivCeil(a, b);
  }
}

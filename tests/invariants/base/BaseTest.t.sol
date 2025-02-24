// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IScaledBalanceToken} from 'src/contracts/interfaces/IScaledBalanceToken.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';
import {IERC20Detailed as IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';

// Libraries
import {Vm} from 'forge-std/Base.sol';
import {StdUtils} from 'forge-std/StdUtils.sol';
import {EModeConfiguration} from 'src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from 'src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {WadRayMath} from 'src/contracts/protocol/libraries/math/WadRayMath.sol';

// Utils
import {Actor} from '../utils/Actor.sol';
import {PropertiesConstants} from '../utils/PropertiesConstants.sol';
import {StdAsserts} from '../utils/StdAsserts.sol';

// Base
import {BaseStorage} from './BaseStorage.t.sol';

/// @notice Base contract for all test contracts extends BaseStorage
/// @dev Provides setup modifier and cheat code setup
/// @dev inherits Storage, Testing constants assertions and utils needed for testing
abstract contract BaseTest is BaseStorage, PropertiesConstants, StdAsserts, StdUtils {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  //bool internal IS_TEST = true;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                   ACTOR PROXY MECHANISM                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @dev Actor proxy mechanism
  modifier setup() virtual {
    actor = actors[msg.sender];
    _setSenderActor(address(actor));
    _;
    _resetActorTargets();
  }

  /// @dev Solves medusa backward time warp issue
  modifier monotonicTimestamp() virtual {
    // Implement monotonic timestamp if needed
    _;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          STRUCTS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice Helper struct to track reserve flags
  struct Flags {
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    bool isPaused;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                     CHEAT CODE SETUP                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @dev Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
  address internal constant VM_ADDRESS = address(uint160(uint256(keccak256('hevm cheat code'))));

  /// @dev Virtual machine instance
  Vm internal constant vm = Vm(VM_ADDRESS);

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          HELPERS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _setSenderActor(address user) internal {
    senderActor = user;
  }

  function _resetSenderActor() internal {
    delete senderActor;
  }

  function _setReceiverActor(address user) internal {
    receiverActor = user;
  }

  function _resetActorTargets() internal virtual {
    delete actor;
    delete senderActor;
    delete receiverActor;
  }

  function _getTargetActor() internal view returns (address) {
    if (receiverActor != address(0)) {
      return receiverActor;
    } else {
      return senderActor;
    }
  }

  function _isActiveActor(address user) internal view returns (bool) {
    return (user == receiverActor || user == senderActor);
  }

  function _resetTargetAsset() internal {
    delete targetAsset;
  }

  /// @notice Get a random address
  function _makeAddr(string memory name) internal pure returns (address addr) {
    uint256 privateKey = uint256(keccak256(abi.encodePacked(name)));
    addr = vm.addr(privateKey);
  }

  /// @notice Get a random actor proxy address
  function _getRandomActor(uint256 _i) internal view returns (address) {
    uint256 _actorIndex = _i % NUMBER_OF_ACTORS;
    return actorAddresses[_actorIndex];
  }

  /// @notice Helper function to deploy a contract from bytecode
  function deployFromBytecode(bytes memory bytecode) internal returns (address child) {
    assembly {
      child := create(0, add(bytecode, 0x20), mload(bytecode))
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                    HELPERS; SCALED TOKENS                                 //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _getReserveNormalizedIncome(address underlyingAsset) internal view returns (uint256) {
    return pool.getReserveNormalizedIncome(underlyingAsset);
  }

  function _getReserveNormalizedVariableDebt(
    address underlyingAsset
  ) internal view returns (uint256) {
    return pool.getReserveNormalizedVariableDebt(underlyingAsset);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      HELPERS: RESERVES                                    //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _getRealTotalSupply(address asset) internal view returns (uint256 totalSupply) {
    uint256 scaledATokenTotalSupply = IAToken(protocolTokens[asset].aTokenAddress)
      .scaledTotalSupply();

    totalSupply = (scaledATokenTotalSupply + pool.getReserveData(asset).accruedToTreasury).rayMul(
      _getReserveNormalizedIncome(asset)
    );
  }

  function _getRealTotalSupply(
    address asset,
    uint256 scaledATokenTotalSupply,
    uint256 accruedToTreasury
  ) internal view returns (uint256) {
    return (scaledATokenTotalSupply + accruedToTreasury).rayMul(_getReserveNormalizedIncome(asset));
  }

  function _isBorrowingAny(address user) internal view returns (bool) {
    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

    return UserConfiguration.isBorrowingAny(userConfig);
  }

  function _getUserScaledDebt(address user, address asset) internal view returns (uint256) {
    return
      IScaledBalanceToken(protocolTokens[asset].variableDebtTokenAddress).scaledBalanceOf(user);
  }

  function _getUserAtokenScaledBalance(
    address user,
    address asset
  ) internal view returns (uint256) {
    return IScaledBalanceToken(protocolTokens[asset].aTokenAddress).scaledBalanceOf(user);
  }

  function _getUserReserveValueInBaseCurrency(
    address asset,
    uint256 balance
  ) internal view returns (uint256) {
    uint256 assetPrice = contracts.aaveOracle.getAssetPrice(asset);
    uint256 assetUnit = 10 ** IERC20(asset).decimals();
    return (balance * assetPrice) / assetUnit;
  }

  function _isBorrowableAsset(address asset) internal view returns (bool) {
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(asset);

    return ReserveConfiguration.getBorrowingEnabled(configuration);
  }

  function _isUsingAsCollateral(address asset, address user) internal view returns (bool) {
    uint256 reserveId = protocolTokens[asset].id;
    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

    return UserConfiguration.isUsingAsCollateral(userConfig, reserveId);
  }

  function _getUserBorrowingAssets(
    address user
  ) internal view returns (address[] memory borrowingAssets) {
    DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

    borrowingAssets = new address[](baseAssets.length);
    uint256 borrowingCount;

    for (uint256 i; i < baseAssets.length; i++) {
      if (UserConfiguration.isBorrowing(userConfig, protocolTokens[baseAssets[i]].id)) {
        borrowingAssets[borrowingCount++] = baseAssets[i];
      }
    }

    // Set the size of the array to the actual number of borrowing assets
    assembly {
      mstore(borrowingAssets, borrowingCount)
    }
  }

  function _getFlags(address asset) internal view returns (Flags memory flags) {
    (bool isActive, bool isFrozen, bool borrowingEnabled, bool isPaused) = pool
      .getConfiguration(asset)
      .getFlags();
    flags = Flags(isActive, isFrozen, borrowingEnabled, isPaused);
  }

  function _isReserveActive(address asset) internal view returns (bool isActive) {
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(asset);

    (isActive, , , ) = ReserveConfiguration.getFlags(configuration);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                    HELPERS: LIQUIDATION                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _getUserHealthFactor(address user) internal view returns (uint256 healthFactor) {
    (, , , , , healthFactor) = pool.getUserAccountData(user);
  }

  function _isHealthy(uint256 healthFactor) internal pure returns (bool) {
    return healthFactor >= 1e18;
  }

  function _isHealthy(address user) internal view returns (bool) {
    return _getUserHealthFactor(user) >= 1e18;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       HELPERS: EMODE                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function _isEModeBorrowableAsset(address asset, uint8 categoryId) internal view returns (bool) {
    uint256 reserveId = protocolTokens[asset].id;
    uint128 isBorrowableBitmap = pool.getEModeCategoryBorrowableBitmap(categoryId);
    return EModeConfiguration.isReserveEnabledOnBitmap(isBorrowableBitmap, reserveId);
  }
  function _isEModeCollateralAsset(address asset, uint8 categoryId) internal view returns (bool) {
    uint256 reserveId = protocolTokens[asset].id;
    uint128 isCollateralBitmap = pool.getEModeCategoryCollateralBitmap(categoryId);
    return EModeConfiguration.isReserveEnabledOnBitmap(isCollateralBitmap, reserveId);
  }
}

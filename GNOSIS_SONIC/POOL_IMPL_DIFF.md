```diff
diff --git a/./downloads/GNOSIS/POOL_IMPL.sol b/./downloads/SONIC/POOL_IMPL.sol
index c910368..ae298e9 100644
--- a/./downloads/GNOSIS/POOL_IMPL.sol
+++ b/./downloads/SONIC/POOL_IMPL.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -574,7 +574,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -681,7 +681,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -700,7 +700,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -790,7 +790,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -866,7 +866,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -1093,7 +1093,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -1123,7 +1123,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -1195,7 +1195,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -1256,7 +1256,7 @@ library PercentageMath {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -1512,7 +1512,7 @@ library SafeCast {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/misc/aave-upgradeability/VersionedInitializable.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/misc/aave-upgradeability/VersionedInitializable.sol
 
 /**
  * @title VersionedInitializable
@@ -1589,7 +1589,7 @@ abstract contract VersionedInitializable {
   uint256[50] private ______gap;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -1715,7 +1715,7 @@ library WadRayMath {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1828,7 +1828,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IACLManager.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -2001,7 +2001,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -2011,7 +2011,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IERC20WithPermit.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IERC20WithPermit.sol
 
 /**
  * @title IERC20WithPermit
@@ -2042,7 +2042,7 @@ interface IERC20WithPermit is IERC20 {
   ) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IPriceOracleSentinel.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IPriceOracleSentinel.sol
 
 /**
  * @title IPriceOracleSentinel
@@ -2107,7 +2107,7 @@ interface IPriceOracleSentinel {
   function getGracePeriod() external view returns (uint256);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -2134,7 +2134,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/math/MathUtils.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/math/MathUtils.sol
 
 /**
  * @title MathUtils library
@@ -2231,7 +2231,7 @@ library MathUtils {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IPool.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -3099,7 +3099,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -3683,7 +3683,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
 
 /**
  * @title EModeConfiguration library
@@ -3732,7 +3732,7 @@ library EModeConfiguration {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/misc/flashloan/interfaces/IFlashLoanReceiver.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/misc/flashloan/interfaces/IFlashLoanReceiver.sol
 
 /**
  * @title IFlashLoanReceiver
@@ -3765,7 +3765,7 @@ interface IFlashLoanReceiver {
   function POOL() external view returns (IPool);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/misc/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/misc/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
 
 /**
  * @title IFlashLoanSimpleReceiver
@@ -3798,7 +3798,7 @@ interface IFlashLoanSimpleReceiver {
   function POOL() external view returns (IPool);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -4030,7 +4030,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -4083,7 +4083,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -4132,7 +4132,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/IsolationModeLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/IsolationModeLogic.sol
 
 /**
  * @title IsolationModeLogic library
@@ -4207,7 +4207,7 @@ library IsolationModeLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IVariableDebtToken.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IVariableDebtToken.sol
 
 /**
  * @title IVariableDebtToken
@@ -4250,7 +4250,7 @@ interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/interfaces/IAToken.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -4384,7 +4384,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -4607,7 +4607,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/ReserveLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/ReserveLogic.sol
 
 /**
  * @title ReserveLogic library
@@ -4909,7 +4909,7 @@ library ReserveLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/pool/PoolStorage.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/pool/PoolStorage.sol
 
 /**
  * @title PoolStorage
@@ -4955,7 +4955,7 @@ contract PoolStorage {
   uint16 internal _reservesCount;
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/EModeLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/EModeLogic.sol
 
 /**
  * @title EModeLogic library
@@ -5017,7 +5017,7 @@ library EModeLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/GenericLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/GenericLogic.sol
 
 /**
  * @title GenericLogic library
@@ -5269,7 +5269,7 @@ library GenericLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/ValidationLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/ValidationLogic.sol
 
 /**
  * @title ValidationLogic library
@@ -5889,7 +5889,7 @@ library ValidationLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/BridgeLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/BridgeLogic.sol
 
 /**
  * @title BridgeLogic library
@@ -6031,7 +6031,7 @@ library BridgeLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/PoolLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/PoolLogic.sol
 
 /**
  * @title PoolLogic library
@@ -6220,7 +6220,7 @@ library PoolLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/SupplyLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/SupplyLogic.sol
 
 /**
  * @title SupplyLogic library
@@ -6508,7 +6508,7 @@ library SupplyLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/BorrowLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/BorrowLogic.sol
 
 /**
  * @title BorrowLogic library
@@ -6731,7 +6731,7 @@ library BorrowLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/LiquidationLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/LiquidationLogic.sol
 
 interface IGhoVariableDebtToken {
   function getBalanceFromInterest(address user) external view returns (uint256);
@@ -7444,7 +7444,7 @@ library LiquidationLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/libraries/logic/FlashLoanLogic.sol
 
 /**
  * @title FlashLoanLogic library
@@ -7704,7 +7704,7 @@ library FlashLoanLogic {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/protocol/pool/Pool.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/protocol/pool/Pool.sol
 
 /**
  * @title Pool contract
@@ -8587,7 +8587,7 @@ abstract contract Pool is VersionedInitializable, PoolStorage, IPool {
   }
 }
 
-// downloads/GNOSIS/POOL_IMPL/PoolInstance/lib/aave-v3-origin/src/contracts/instances/PoolInstance.sol
+// downloads/SONIC/POOL_IMPL/PoolInstance/src/contracts/instances/PoolInstance.sol
 
 contract PoolInstance is Pool {
   uint256 public constant POOL_REVISION = 7;
```

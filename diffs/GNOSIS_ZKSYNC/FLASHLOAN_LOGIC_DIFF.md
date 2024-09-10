```diff
diff --git a/./downloads/GNOSIS/FLASHLOAN_LOGIC.sol b/./downloads/ZKSYNC/FLASHLOAN_LOGIC.sol
index 4935973..5c4cbd2 100644
--- a/./downloads/GNOSIS/FLASHLOAN_LOGIC.sol
+++ b/./downloads/ZKSYNC/FLASHLOAN_LOGIC.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -334,7 +334,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -410,7 +410,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -666,7 +666,7 @@ library SafeCast {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -685,7 +685,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -912,7 +912,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -942,7 +942,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -1014,7 +1014,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -1122,7 +1122,7 @@ library Errors {
   string public constant INVALID_FREEZE_STATE = '99'; // Reserve is already in the passed freeze state
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -1183,7 +1183,7 @@ library PercentageMath {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -1309,7 +1309,7 @@ library WadRayMath {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -1622,7 +1622,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1735,7 +1735,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1745,7 +1745,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1918,7 +1918,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPriceOracleSentinel.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPriceOracleSentinel.sol
 
 /**
  * @title IPriceOracleSentinel
@@ -1983,7 +1983,7 @@ interface IPriceOracleSentinel {
   function getGracePeriod() external view returns (uint256);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -2011,7 +2011,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256, uint256);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/MathUtils.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/math/MathUtils.sol
 
 /**
  * @title MathUtils library
@@ -2108,7 +2108,7 @@ library MathUtils {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPool.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2940,7 +2940,7 @@ interface IPool {
   function getSupplyLogic() external returns (address);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -3577,7 +3577,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/helpers/Helpers.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/helpers/Helpers.sol
 
 /**
  * @title Helpers library
@@ -3602,7 +3602,7 @@ library Helpers {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
 
 /**
  * @title IFlashLoanReceiver
@@ -3635,7 +3635,7 @@ interface IFlashLoanReceiver {
   function POOL() external view returns (IPool);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol
 
 /**
  * @title IFlashLoanSimpleReceiver
@@ -3668,7 +3668,7 @@ interface IFlashLoanSimpleReceiver {
   function POOL() external view returns (IPool);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -3900,7 +3900,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IInitializableAToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -3953,7 +3953,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -4002,7 +4002,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IStableDebtToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IStableDebtToken.sol
 
 /**
  * @title IStableDebtToken
@@ -4139,7 +4139,7 @@ interface IStableDebtToken is IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/IsolationModeLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/IsolationModeLogic.sol
 
 /**
  * @title IsolationModeLogic library
@@ -4198,7 +4198,7 @@ library IsolationModeLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IVariableDebtToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IVariableDebtToken.sol
 
 /**
  * @title IVariableDebtToken
@@ -4241,7 +4241,7 @@ interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IAToken.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -4375,7 +4375,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -4599,7 +4599,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/ReserveLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/ReserveLogic.sol
 
 /**
  * @title ReserveLogic library
@@ -4959,7 +4959,7 @@ library ReserveLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/EModeLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/EModeLogic.sol
 
 /**
  * @title EModeLogic library
@@ -5060,7 +5060,7 @@ library EModeLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/GenericLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/GenericLogic.sol
 
 /**
  * @title GenericLogic library
@@ -5318,7 +5318,7 @@ library GenericLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/ValidationLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/ValidationLogic.sol
 
 /**
  * @title ReserveLogic library
@@ -6078,7 +6078,7 @@ library ValidationLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/BorrowLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/BorrowLogic.sol
 
 /**
  * @title BorrowLogic library
@@ -6422,7 +6422,7 @@ library BorrowLogic {
   }
 }
 
-// downloads/GNOSIS/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/FlashLoanLogic.sol
+// downloads/ZKSYNC/FLASHLOAN_LOGIC/FlashLoanLogic/src/core/contracts/protocol/libraries/logic/FlashLoanLogic.sol
 
 /**
  * @title FlashLoanLogic library
```

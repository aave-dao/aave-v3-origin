```diff
diff --git a/./downloads/GNOSIS/SUPPLY_LOGIC.sol b/./downloads/CELO/SUPPLY_LOGIC.sol
index f92a961..cdb3a7c 100644
--- a/./downloads/GNOSIS/SUPPLY_LOGIC.sol
+++ b/./downloads/CELO/SUPPLY_LOGIC.sol
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: BUSL-1.1
 pragma solidity ^0.8.0 ^0.8.10;
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/Address.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
 
@@ -221,7 +221,7 @@ library Address {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/Context.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/Context.sol
 
 /*
  * @dev Provides information about the current execution context, including the
@@ -244,7 +244,7 @@ abstract contract Context {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/types/DataTypes.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/types/DataTypes.sol
 
 library DataTypes {
   /**
@@ -574,7 +574,7 @@ library DataTypes {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/helpers/Errors.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/helpers/Errors.sol
 
 /**
  * @title Errors library
@@ -681,7 +681,7 @@ library Errors {
   string public constant USER_CANNOT_HAVE_DEBT = '104'; // Thrown when a user tries to interact with a method that requires a position without debt
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IAaveIncentivesController.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IAaveIncentivesController.sol
 
 /**
  * @title IAaveIncentivesController
@@ -700,7 +700,7 @@ interface IAaveIncentivesController {
   function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol
 
 /**
  * @dev External interface of AccessControl declared to support ERC165 detection.
@@ -790,7 +790,7 @@ interface IAccessControl {
   function renounceRole(bytes32 role, address account) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20.sol
 
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -866,7 +866,7 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPoolAddressesProvider.sol
 
 /**
  * @title IPoolAddressesProvider
@@ -1093,7 +1093,7 @@ interface IPoolAddressesProvider {
   function setPoolDataProvider(address newDataProvider) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPriceOracleGetter.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPriceOracleGetter.sol
 
 /**
  * @title IPriceOracleGetter
@@ -1123,7 +1123,7 @@ interface IPriceOracleGetter {
   function getAssetPrice(address asset) external view returns (uint256);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IScaledBalanceToken.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IScaledBalanceToken.sol
 
 /**
  * @title IScaledBalanceToken
@@ -1195,7 +1195,7 @@ interface IScaledBalanceToken {
   function getPreviousIndex(address user) external view returns (uint256);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/PercentageMath.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/PercentageMath.sol
 
 /**
  * @title PercentageMath library
@@ -1256,7 +1256,7 @@ library PercentageMath {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/SafeCast.sol
 
 // OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
 
@@ -1512,7 +1512,7 @@ library SafeCast {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/WadRayMath.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/WadRayMath.sol
 
 /**
  * @title WadRayMath library
@@ -1638,7 +1638,7 @@ library WadRayMath {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol
 
 /// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
 /// @author Gnosis Developers
@@ -1751,7 +1751,7 @@ library GPv2SafeERC20 {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IACLManager.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IACLManager.sol
 
 /**
  * @title IACLManager
@@ -1924,7 +1924,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol
 
 interface IERC20Detailed is IERC20 {
   function name() external view returns (string memory);
@@ -1934,7 +1934,7 @@ interface IERC20Detailed is IERC20 {
   function decimals() external view returns (uint8);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPriceOracleSentinel.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPriceOracleSentinel.sol
 
 /**
  * @title IPriceOracleSentinel
@@ -1999,7 +1999,7 @@ interface IPriceOracleSentinel {
   function getGracePeriod() external view returns (uint256);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IReserveInterestRateStrategy.sol
 
 /**
  * @title IReserveInterestRateStrategy
@@ -2026,7 +2026,7 @@ interface IReserveInterestRateStrategy {
   ) external view returns (uint256, uint256);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/MathUtils.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/math/MathUtils.sol
 
 /**
  * @title MathUtils library
@@ -2123,7 +2123,7 @@ library MathUtils {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPool.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IPool.sol
 
 /**
  * @title IPool
@@ -2991,7 +2991,7 @@ interface IPool {
   function getSupplyLogic() external view returns (address);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
 
 /**
  * @title ReserveConfiguration library
@@ -3575,7 +3575,7 @@ library ReserveConfiguration {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/EModeConfiguration.sol
 
 /**
  * @title EModeConfiguration library
@@ -3624,7 +3624,7 @@ library EModeConfiguration {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/configuration/UserConfiguration.sol
 
 /**
  * @title UserConfiguration library
@@ -3856,7 +3856,7 @@ library UserConfiguration {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IInitializableAToken.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IInitializableAToken.sol
 
 /**
  * @title IInitializableAToken
@@ -3909,7 +3909,7 @@ interface IInitializableAToken {
   ) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IInitializableDebtToken.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IInitializableDebtToken.sol
 
 /**
  * @title IInitializableDebtToken
@@ -3958,7 +3958,7 @@ interface IInitializableDebtToken {
   ) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IVariableDebtToken.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IVariableDebtToken.sol
 
 /**
  * @title IVariableDebtToken
@@ -4001,7 +4001,7 @@ interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
   function UNDERLYING_ASSET_ADDRESS() external view returns (address);
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IAToken.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/interfaces/IAToken.sol
 
 /**
  * @title IAToken
@@ -4135,7 +4135,7 @@ interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
   function rescueTokens(address token, address to, uint256 amount) external;
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/tokenization/base/IncentivizedERC20.sol
 
 /**
  * @title IncentivizedERC20
@@ -4358,7 +4358,7 @@ abstract contract IncentivizedERC20 is Context, IERC20Detailed {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/ReserveLogic.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/ReserveLogic.sol
 
 /**
  * @title ReserveLogic library
@@ -4660,7 +4660,7 @@ library ReserveLogic {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/EModeLogic.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/EModeLogic.sol
 
 /**
  * @title EModeLogic library
@@ -4722,7 +4722,7 @@ library EModeLogic {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/GenericLogic.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/GenericLogic.sol
 
 /**
  * @title GenericLogic library
@@ -4974,7 +4974,7 @@ library GenericLogic {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/ValidationLogic.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/ValidationLogic.sol
 
 /**
  * @title ValidationLogic library
@@ -5594,7 +5594,7 @@ library ValidationLogic {
   }
 }
 
-// downloads/GNOSIS/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/SupplyLogic.sol
+// downloads/CELO/SUPPLY_LOGIC/SupplyLogic/src/contracts/protocol/libraries/logic/SupplyLogic.sol
 
 /**
  * @title SupplyLogic library
```

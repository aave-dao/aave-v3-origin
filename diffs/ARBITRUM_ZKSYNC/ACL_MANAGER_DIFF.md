```diff
diff --git a/./downloads/ARBITRUM/ACL_MANAGER.sol b/./downloads/ZKSYNC/ACL_MANAGER.sol
index 9ff4476..88e1973 100644
--- a/./downloads/ARBITRUM/ACL_MANAGER.sol
+++ b/./downloads/ZKSYNC/ACL_MANAGER.sol

-// downloads/ARBITRUM/ACL_MANAGER/ACLManager/@aave/core-v3/contracts/interfaces/IACLManager.sol
+// downloads/ZKSYNC/ACL_MANAGER/ACLManager/src/core/contracts/interfaces/IACLManager.sol

 /**
  * @title IACLManager
  * @author Aave
  * @notice Defines the basic interface for the ACL Manager
- **/
+ */
 interface IACLManager {
   /**
    * @notice Returns the contract address of the PoolAddressesProvider
@@ -676,7 +684,7 @@ interface IACLManager {
   function addFlashBorrower(address borrower) external;

   /**
-   * @notice Removes an admin as FlashBorrower
+   * @notice Removes an address as FlashBorrower
    * @param borrower The address of the FlashBorrower to remove
    */
   function removeFlashBorrower(address borrower) external;
@@ -727,7 +735,7 @@ interface IACLManager {
   function isAssetListingAdmin(address admin) external view returns (bool);
 }

```

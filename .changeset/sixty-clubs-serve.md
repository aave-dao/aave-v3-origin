---
"@aave-dao/aave-v3-origin": patch
---

In order to separate "dust", that is initially deposited on asset listing, from the treasury income a new "dustBin" contract was introduced. It does not hold any functionality, besides being upgradable by the DAO.

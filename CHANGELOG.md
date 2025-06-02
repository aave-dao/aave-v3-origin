# @aave-dao/aave-v3-origin

## 3.3.1

### Patch Changes

- bb6ea42: Added changesets, Added release workflow, Updated gas snapshots to run in isolation
- a0512f8: In order to separate "dust", that is initially deposited on asset listing, from the treasury income a new "dustBin" contract was introduced. It does not hold any functionality, besides being upgradable by the DAO.

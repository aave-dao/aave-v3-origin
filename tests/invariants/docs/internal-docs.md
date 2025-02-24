# Internal Documentation for the Aave v3 Invariant Testing Suite

## Table of Contents

1. [Running the Suite](#running-the-suite)

   - Prerequisites
   - Starting the Suite
   - Configurations

2. [Property Formats](#property-formats)

   - Invariants
   - Postconditions
     - Global Postconditions (GPOST)
     - Handler-Specific Postconditions (HSPOST)

3. [Handlers: Adding Support for New Functions](#handlers-adding-support-for-new-functions)

   - Overview
   - Adding New Functions
   - Testing New Functions

4. [Migrating Tests from Foundry](#migrating-tests-from-foundry)

   - Overview
   - Migration Steps

5. [Migrating Certora Properties](#migrating-certora-properties)

   - Overview
   - Property Mapping
   - Migration Guide

6. [Debugging Broken Properties](#debugging-broken-properties)

   - Logging & Output
   - Crytic to Foundry Test Helper
   - Steps to Reproduce an Echidna Error Inside the Foundry Wrapper

## Running the Suite

- **Prerequisites**:

  - Ensure that all protocol dependencies have been installed:

    ```sh
    cp .env.example .env

    forge install
    ```

  - Make sure the latest version of **Echidna** is installed. If it is not installed, you can follow the guide [HERE](https://github.com/crytic/echidna?tab=readme-ov-file#installation) to install it.

  <br />

- **Starting the Suite**: The suite is able to check the invariants and postconditions of the Aave v3 protocol. For that it uses two different modes, property mode and assertion mode respectively.

  - **Property Mode**: Checks protocol invariants. Run with:
    ```sh
    make echidna
    ```
  - **Assertion Mode**: Checks protocol postconditions. Run with:

    ```sh
    make echidna-assert
    ```

  - **Extra**: Run the suites without checking for properties, only increasing corpus size and coverage. Run with:
    ```sh
    make echidna-explore
    ```

  <br />

- **Configurations**: The suite configuration can be found in the [echidna_config.yaml](../_config/echidna_config.yaml) file. This file contains the configuration for the Echidna testing tool, the following are the most important parameters of the configuration:

  - **seqLen**: Defines the number of calls in each test sequence.
  - **maxDepth**: Sets the total number of test sequences to execute.
  - **coverage**: Enables coverage tracking, stored in the directory specified by `corpusDir`.
  - **corpusDir**: Directory for saving coverage data. In this suite, coverage is saved in `tests/invariants/_corpus/echidna/default/_data/corpus`.
  - **deployContracts**: Predeploys required libraries to ensure compatibility with Echidna and the underlying hevm, particularly for Aave v3, which relies on many libraries. Libraries are linked using the `cryticArgs` parameter with the `--compile-libraries` flag.
  - **workers**: Sets the number of parallel threads for Echidna, ideally close to the machine's CPU thread count for optimal performance.
    <br />

## Property Formats

As mentioned on the public documentation this suite framework spins around to types of properties, **invariants** and **postconditions**. The following section will provide a detailed explanation of each type of property and how they are implemented.

### Invariants

- **Definition**: Invariants are properties that must hold true across all states of the system. These are checked when the tool runs under property-mode, making echidna call all public functions starting with `echidna_` and making sure the assertions in those do not fail. These checks happen in between every call inside test sequences.
- **Example**: BASE_INVARIANT_A

  - **Spec**: debtToken totalSupply should be equal to the sum of all user balances (user debt).
  - **Implementation**: `BaseInvariants::assert_BASE_INVARIANT_A`

    ```solidity
    function assert_BASE_INVARIANT_A(IERC20 debtToken) internal {
      uint256 sumOfUserBalances;
      for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
        sumOfUserBalances += debtToken.balanceOf(actorAddresses[i]);
      }
      assertEq(debtToken.totalSupply(), sumOfUserBalances, BASE_INVARIANT_A);
    }
    ```

    Every implementation of an invariant must be called inside its wrapper `echidna_**` function on the `Invariants.sol` file, as shown in the following code snippet:

    ```solidity
    function echidna_BASE_INVARIANT_A() public returns (bool) {
      for (uint256 i; i < debtTokens.length; ++i) {
        /// <--- Looping through all debt tokens,
        /// since the suite setup uses three reserves, this loop will run three times.
        assert_BASE_INVARIANT_A(IERC20(debtTokens[i]));
      }
      return true;
    }
    ```

- **Implementation Guide**:
  - Define core properties of the protocol (e.g., balance constraints, liquidity checks, internal accounting accuracy).
  - Keep assertions clear and straightforward. If looping through users, assets, or reserves, aim for simplicity—avoid excessive or complex logic to maintain efficiency and readability (check example above looping through the suite actors).
  - Minimize redundancy by ensuring invariants don’t overlap too heavily with each other. However, certain degree of overlap can be beneficial for covering more scenarios, so consider strategic overlaps to maximize checks coverage.

### Postconditions

- **Definition**: Postconditions are properties that must hold true following specific actions or interactions within a test sequence. They help ensure that each action in the sequence produces a valid protocol state, focusing on targeted outcomes rather than overall system-wide conditions. Unlike invariants, which are checked consistently across states, postconditions are enforced at designated points. These points include the end of each handler call (for handler-specific postconditions) or at the end of the `_after` hook (for global postconditions), validating the expected results of specific actions.

  As the public documentation states, these checks are performed in assertion-mode, where echidna report a failing alert after detecting a `Panic(1)` error coming from a failed `assert` statement.

- **Categories**: These postconditions can fall into two categories, the global postconditions and the handler-specific postconditions. The global postconditions (GPOST) are checked at the end of each test sequence using the `_after` hook, while the handler-specific postconditions (HSPOST) are checked at the end of specific handler calls.

- **Example GPOST**: LENDING_GPOST_C

  - **Spec**: If totalSupply for a reserve increases new totalSupply must be less than or equal to supply cap.
  - **Implementation**: `DefaultBeforeAfterHooks::assert_LENDING_GPOST_C`

    ```solidity
    function assert_LENDING_GPOST_C() internal {
      if (targetAsset == address(0)) return;
      uint256 totalSupplyUpdatedTreasury = _getRealTotalSupply(
        targetAsset,
        defaultVarsBefore.scaledTotalSupply,
        defaultVarsAfter.accruedToTreasury
      );
      if (totalSupplyUpdatedTreasury < defaultVarsAfter.totalSupply) {
        if (
          defaultVarsAfter.supplyCap != 0 &&
          msg.sig != IPoolHandler.mintToTreasury.selector
        )
          assertLe(
            defaultVarsAfter.totalSupply,
            defaultVarsAfter.supplyCap,
            LENDING_GPOST_C
          );
      }
    }
    ```

    Every global postcondition must be called at the end of the `_after` hook in the `_checkPostConditions` function, as shown in the following code snippet:

    ```solidity
    function _checkPostConditions() internal {
      // Implement post conditions here
      ...

      // LENDING
      assert_LENDING_GPOST_C(); /// <--- Global postcondition execution

      ...
    }
    ```

- **Example HSPOST**: E_MODE_HSPOST_G

  - **Spec**: The health factor of the user must be >= 1 after switch or leaving an emode.
  - **Implementation**: At the end of the `setUserEMode` handler, the postcondition is checked.

    ```solidity
    function setUserEMode(uint8 i) external setup {
      bool success;
      bytes memory returnData;

      ... /// <--- variable caching, actor-call, etc. summarized for brevity

      if (success) {
        _after();

        // POST-CONDITIONS
        if (eModeCategory != previousUserEModeCategory) {
          ...
          assertGe(_getUserHealthFactor(address(actor)), 1, E_MODE_HSPOST_G); /// <--- Postcondition
        }
      }
    }
    ```

- **Implementation Guide**:
  - Identify key outcomes or state changes that should result from each action (e.g., balance updates, collateral adjustments, interest accruals).
  - Aim to complement invariants with global postconditions, ensuring that properties that are not possible to be implemented as invariants are still covered.
    <br />

## Handlers: Adding Support for New Functions

- **Overview**: As the public documentation states, handlers act as a kind of middleware layer between the tooling and the protocol. That is why when new features are added to the protocol or this one is upgraded, new handler functions must be either added or updated to support the new features. The following section will provide a detailed explanation of how to add support for new functions in handlers.
- **Adding New Functions**: Let's take the example of the Aave v3.2 upgrade where a more granular version of the eMode feature was introduced. The new feature allows assets to be listed in multiple eModes removing `setAssetEModeCategory` function in favor of two more granular functions `setAssetCollateralInEMode` and `setAssetBorrowableInEMode`. The following steps show a guide through the process of adding support for these new functions in the handlers:

  - **Identify the Handler**: Determine which handler contract will be responsible for the new functions. In this case, the `PoolPermissionedHandler` handler is responsible for all the permissioned interactions with the protocol, so support the new functions should be added here.

  - **Identify the parameters**: Determine which parameters are needed for the actions, which ones can be randomized, which ones should be clamped and which ones should be taken from a finite set like a helper storage array.+

    In the case of the `setAssetCollateralInEMode` and `setAssetBorrowableInEMode` functions, the parameters are as follows:

    - `asset`: The address of the asset to be set in the eMode.
    - `eModeCategory`: The eMode category to set the asset to.
    - `allowed`: A boolean value to set if the asset is allowed in the eMode.

    For the `asset` parameter, a random base asset can be selected from the helper storage array `baseAssets` using `_getRandomBaseAsset` function and for the `eModeCategory` parameter, a random eMode category can be selected from the helper storage array `ghost_categoryIds` using the `_getRandomEModeCategory` function.
    Lastly for the `allowed` parameter, a random boolean parameter can be used.

  - **Identify if the action is permissioned or permissionless**: If the action is permissioned, using actors as proxy is not needed since the suite is setup as the poolAdmin so a direct call to the handler is enough. If the action is permissionless, an actor-proxied call must be used along with the `setup` actor selection modifier. The following code is how the two functions implementation would look like:

    ```solidity
    function setAssetCollateralInEMode(
      bool allowed,
      uint8 i,
      uint8 j
    ) external {
      address asset = _getRandomBaseAsset(i); /// <--- Random base asset selection

      uint8 categoryId = _getRandomEModeCategory(j); /// <--- Random eCategory selection

      // Direct call to the handler, since the suite has the poolAdmin role
      contracts.poolConfiguratorProxy.setAssetCollateralInEMode(
        asset,
        categoryId,
        allowed
      );
    }
    ```

    How a permissionless action would look like:

    - `eModeCategory` parameter is needed for the action, so a random eMode category can be selected from the helper storage array `ghost_categoryIds` using the `_getRandomEModeCategory` function.
    - Function should be called by an actor so the `setup` modifier and a proxied call to the protocol are used.
    - The function should be called between the `_before` and `_after` hooks to ensure values are cached for postconditions to be checked properly.

    ```solidity
    function setUserEMode(uint8 i) external setup {
      bool success; /// <--- Variables to store the success of the call and return data
      bytes memory returnData;

      uint8 eModeCategory = _getRandomEModeCategory(i); /// <--- Random eMode category selection

      uint256 previousUserEModeCategory = pool.getUserEMode(address(actor));

      address target = address(pool);

      address[] memory assetsBorrowing = _getUserBorrowingAssets(
        address(actor)
      ); /// <--- Cached required variables for postconditions checks

      _before(); /// <--- Before hook
      (success, returnData) = actor.proxy( /// <--- Proxied call to the protocol
        target,
        abi.encodeWithSelector(IPool.setUserEMode.selector, eModeCategory)
      );

      if (success) {
        _after(); /// <--- After hook on success

        // POST-CONDITIONS
        if (eModeCategory != previousUserEModeCategory) {
          /// <--- Postconditions checks
          assertAssetsBorrowableInEmode(
            assetsBorrowing,
            eModeCategory,
            E_MODE_HSPOST_H
          );
          assertGe(_getUserHealthFactor(address(actor)), 1, E_MODE_HSPOST_G);
        }
      }
    }
    ```

  - **Update Postconditions**: If the new functions introduce changes to the protocol state, update the postconditions to reflect these changes. For example, if with the new update eModes the health factor of the user must be >= 1 after switch or leaving an emode. postcondition `E_MODE_HSPOST_G` should be implemented like shown in the example above.
    <br />

- **Testing**: After adding the new handler functions and updating the postconditions, run the tooling to make sure the new logic is being covered and work correctly. You can check for html coverage reports inside `echidna/default/_data/corpus` directory.
  <br />

## Migrating Tests from Foundry

- **Overview**: Foundry unit and staless tests assertions are tightly related to handler specific postconditions, since both execute a determined action or set of actions and check for relationships and properties to hold after its executions. It is possible to migrate a big portion of these tests and assertions to the suite (some of the current postconditions already take inspiration on those), ensuring that the protocol is still being tested for the same properties and relationships between variables.
- **Step-by-Step Migration**:

  1.  Identifying the action to migrate on both environments. For example, the `borrow` function.
  2.  Translating the Foundry assertions into postconditions or even invariants. For example on the test `test_variable_borrow` this common assertion `assertEq(balanceAfter, balanceBefore + borrowAmount);` can be translated to the following postcondition:
      `BORROWING_HSPOST_I: After a successful borrow the actor asset balance should increase by the amount borrowed`

            This can be implemented at the end of the `borrow` handler function like shown below:

            ```solidity
            function borrow(uint256 amount, uint8 i, uint8 j) external setup {
                bool success;
                bytes memory returnData;

                ...
                uint256 actorAssetBalanceBefore = IERC20(asset).balanceOf(address(actor));

                _before();
                (success, returnData) = actor.proxy(
                address(pool),
                abi.encodeWithSelector(
                    IPool.borrow.selector,
                    asset,
                    amount,
                    DataTypes.InterestRateMode.VARIABLE,
                    0,
                    onBehalfOf
                )
                );
                ...

                if (success) {
                _after();
                // POST-CONDITIONS
                assertEq( /// <--- Postcondition BORROWING_HSPOST_I migrated from Foundry
                    IERC20(asset).balanceOf(address(actor)),
                    actorAssetBalanceBefore + amount,
                    BORROWING_HSPOST_I
                );
                ...
                }
            }
            ```

  3.  Re-running tests using assertion mode to ensure the new property holds across a much wider number of states.
      <br />

## Migrating Certora Properties

- **Overview**: Certora's framework aligns closely with the suite’s approach, so many Certora properties can be directly migrated into the suite. Adjustments to format and structure may be needed, but core logic should translate well. On top of this, since the suite is actor-based and uses a finite set of actors, properties that involve calculating sums of user values can be easily implemented, for example `BASE_INVARIANT_A`.
- **Types of Properties**: Below is a mapping of Certora property types to Enigma Suite property types, highlighting how each translates in the suite:

| Certora Property            | Enigma Suite Property |
| --------------------------- | --------------------- |
| `invariant` functions       | Invariants            |
| `rule` functions            | HSPOST postconditions |
| Parametric `rule` functions | GPOST postconditions  |

- **Migration Guide**:
  - **Invariants**: Certora `invariant` functions that check protocol-wide conditions can generally be implemented as the suite’s invariant checks.
  - **Postconditions**:
    - Certora `rule` functions often align with the suite's **Handler-Specific Postconditions (HSPOST)**, which are checked after individual handler calls.
    - Parametric `rule` functions in Certora, which implement rules for all protocol actions, translate to **Global Postconditions (GPOST)** in the suite, allowing protocol-wide checks post-execution.

Adapt each property carefully, especially those involving parameterization or dependencies on specific protocol states. While the property frameworks between Certora and the suite are conceptually similar, the engine, execution process, and environment vary significantly between **formal verification** (Certora) and **coverage-guided fuzzing** (the Enigma Suite). This difference may affect certain assumptions.
<br />

## Debugging Broken Properties

- **Logging & Output**: While running, Echidna displays a terminal UI that reports the status of properties—either passing or failing—along with relevant call traces. When a property fails, some threads initiate a "shrinking" process to simplify the call trace, making debugging easier. The amount of shrinking effort can be adjusted in the `echidna_config.yaml` file using the `shrinkLimit` parameter.
  After shrinking completes for a failing property, the suite can be stopped with `Ctrl+C`. Corpus and coverage data are saved automatically, and the dashboard's information is output to the command line, allowing to copy the minimized call trace for further debugging with Foundry wrapper tests.

- **Crytic to foundry test helper**: `CryticToFoundry` file serves as a call trace reproducer where call traces from echidna output can be debugged easily. The following is an example of how to use the helper for a failing property:

  ```solidity
  function test_borrow_assertion() public {
    _setUpActorAndDelay(USER1, 453881);
    this.approveDelegation(
      1482526189130252178123437018605205213532554266044322803735452163998541884248,
      226,
      251
    );
    _setUpActorAndDelay(USER1, 42941);
    this.supply(1000000000000000001, 33, 89);
    _setUpActorAndDelay(USER1, 67960);
    this.setEModeCategory(118, 189, 2300, 30039);
    _setUpActorAndDelay(USER2, 287316);
    this.setUserEMode(145);
    _setUpActorAndDelay(USER2, 438639);
    this.borrow(2848252610, 0, 2);
  }
  ```

- **Steps to reproduce an Echidna error inside the Foundry wrapper**:
  - Copy the call trace from the Echidna output.
  - Initiate the `echidna_parser.py` tool.
  - Paste the call trace into the tool.
  - Hit enter to generate the Foundry wrapper test.
  - Copy the generated test and paste it into the `CryticToFoundry` file.
  - Run the test and debug the failing property using foundry verbose output `-vvvv`.

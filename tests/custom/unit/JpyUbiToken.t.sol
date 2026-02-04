// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import {JUBCToken} from 'custom/jubc/JUBCToken.sol';

/**
 * @title JUBCTokenTest
 * @notice Comprehensive unit tests for JUBCToken contract
 * @dev Tests cover:
 *      - ACL (Access Control)
 *      - Facilitator management
 *      - Bucket enforcement
 *      - Mint/burn operations
 *      - All error conditions with exact error messages
 *      - Success cases following error cases
 *      - Fuzzing on all numeric parameters
 */
contract JUBCTokenTest is Test {
  JUBCToken public jpyUbi;

  address public admin;
  address public facilitatorManager;
  address public bucketManager;
  address public facilitator1;
  address public facilitator2;
  address public user1;
  address public user2;
  address public attacker;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 public constant FACILITATOR_MANAGER_ROLE = keccak256('FACILITATOR_MANAGER_ROLE');
  bytes32 public constant BUCKET_MANAGER_ROLE = keccak256('BUCKET_MANAGER_ROLE');

  uint128 public constant DEFAULT_BUCKET_CAPACITY = 1_000_000e18;

  // ══════════════════════════════════════════════════════════════════════════════
  // EVENTS
  // ══════════════════════════════════════════════════════════════════════════════

  event FacilitatorAdded(address indexed facilitatorAddress, bytes32 indexed label, uint256 bucketCapacity);
  event FacilitatorRemoved(address indexed facilitator);
  event FacilitatorBucketCapacityUpdated(address indexed facilitator, uint256 oldCapacity, uint256 newCapacity);
  event FacilitatorBucketLevelUpdated(address indexed facilitator, uint256 oldLevel, uint256 newLevel);

  // ══════════════════════════════════════════════════════════════════════════════
  // SETUP
  // ══════════════════════════════════════════════════════════════════════════════

  function setUp() public {
    admin = makeAddr('admin');
    facilitatorManager = makeAddr('facilitatorManager');
    bucketManager = makeAddr('bucketManager');
    facilitator1 = makeAddr('facilitator1');
    facilitator2 = makeAddr('facilitator2');
    user1 = makeAddr('user1');
    user2 = makeAddr('user2');
    attacker = makeAddr('attacker');

    vm.startPrank(admin);
    jpyUbi = new JUBCToken(admin);
    jpyUbi.grantRole(FACILITATOR_MANAGER_ROLE, facilitatorManager);
    jpyUbi.grantRole(BUCKET_MANAGER_ROLE, bucketManager);
    vm.stopPrank();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_constructor_setsCorrectNameAndSymbol() public view {
    assertEq(jpyUbi.name(), 'ZaiBots AI Economic Nation');
    assertEq(jpyUbi.symbol(), 'AIEN');
    assertEq(jpyUbi.decimals(), 18);
  }

  function test_constructor_grantsAdminRole() public view {
    assertTrue(jpyUbi.hasRole(DEFAULT_ADMIN_ROLE, admin));
  }

  function testFuzz_constructor_anyAdmin(address _admin) external {
    vm.assume(_admin != address(0));
    JUBCToken token = new JUBCToken(_admin);
    assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, _admin));
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ACL TESTS - FACILITATOR_MANAGER_ROLE
  // ══════════════════════════════════════════════════════════════════════════════

  function test_addFacilitator_onlyFacilitatorManager() public {
    // Should fail: attacker doesn't have role
    vm.prank(attacker);
    vm.expectRevert();
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Should succeed: facilitatorManager has role
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Verify facilitator was added
    JUBCToken.Facilitator memory f = jpyUbi.getFacilitator(facilitator1);
    assertEq(f.label, 'Facilitator 1');
    assertEq(f.bucketCapacity, DEFAULT_BUCKET_CAPACITY);
  }

  function test_removeFacilitator_onlyFacilitatorManager() public {
    // Setup: add facilitator
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Should fail: attacker doesn't have role
    vm.prank(attacker);
    vm.expectRevert();
    jpyUbi.removeFacilitator(facilitator1);

    // Should succeed: facilitatorManager has role
    vm.prank(facilitatorManager);
    jpyUbi.removeFacilitator(facilitator1);

    // Verify facilitator was removed
    JUBCToken.Facilitator memory f = jpyUbi.getFacilitator(facilitator1);
    assertEq(f.label, '');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ACL TESTS - BUCKET_MANAGER_ROLE
  // ══════════════════════════════════════════════════════════════════════════════

  function test_setFacilitatorBucketCapacity_onlyBucketManager() public {
    // Setup: add facilitator
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Should fail: attacker doesn't have role
    vm.prank(attacker);
    vm.expectRevert();
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, DEFAULT_BUCKET_CAPACITY * 2);

    // Should succeed: bucketManager has role
    vm.prank(bucketManager);
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, DEFAULT_BUCKET_CAPACITY * 2);

    // Verify capacity was updated
    (uint256 capacity, ) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(capacity, DEFAULT_BUCKET_CAPACITY * 2);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FACILITATOR MANAGEMENT - ERROR CONDITIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_addFacilitator_revert_alreadyExists() public {
    vm.startPrank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Should fail: facilitator already exists
    vm.expectRevert(JUBCToken.FacilitatorAlreadyExists.selector);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1 Duplicate', DEFAULT_BUCKET_CAPACITY);
    vm.stopPrank();
  }

  function test_removeFacilitator_revert_doesNotExist() public {
    vm.prank(facilitatorManager);
    vm.expectRevert(JUBCToken.InvalidFacilitator.selector);
    jpyUbi.removeFacilitator(facilitator1);
  }

  function test_removeFacilitator_revert_bucketLevelNotZero() public {
    // Setup: add facilitator and mint some tokens
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, 1000e18);

    // Should fail: bucket level > 0
    vm.prank(facilitatorManager);
    vm.expectRevert(JUBCToken.BucketLevelExceeded.selector);
    jpyUbi.removeFacilitator(facilitator1);
  }

  function test_setFacilitatorBucketCapacity_revert_doesNotExist() public {
    vm.prank(bucketManager);
    vm.expectRevert(JUBCToken.InvalidFacilitator.selector);
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, DEFAULT_BUCKET_CAPACITY);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FACILITATOR MANAGEMENT - SUCCESS AFTER ERROR
  // ══════════════════════════════════════════════════════════════════════════════

  function test_addFacilitator_successAfterRoleGranted() public {
    // First attempt fails
    vm.prank(attacker);
    vm.expectRevert();
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Grant role
    vm.prank(admin);
    jpyUbi.grantRole(FACILITATOR_MANAGER_ROLE, attacker);

    // Now succeeds
    vm.prank(attacker);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    JUBCToken.Facilitator memory f = jpyUbi.getFacilitator(facilitator1);
    assertEq(f.label, 'Facilitator 1');
  }

  function test_removeFacilitator_successAfterBurnToZero() public {
    // Setup
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, 1000e18);

    // First attempt fails
    vm.prank(facilitatorManager);
    vm.expectRevert(JUBCToken.BucketLevelExceeded.selector);
    jpyUbi.removeFacilitator(facilitator1);

    // Transfer tokens to facilitator and burn
    vm.prank(user1);
    jpyUbi.transfer(facilitator1, 1000e18);

    vm.prank(facilitator1);
    jpyUbi.burn(1000e18);

    // Now succeeds
    vm.prank(facilitatorManager);
    jpyUbi.removeFacilitator(facilitator1);

    JUBCToken.Facilitator memory f = jpyUbi.getFacilitator(facilitator1);
    assertEq(f.label, '');
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MINT - ERROR CONDITIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_mint_revert_notFacilitator() public {
    vm.prank(attacker);
    vm.expectRevert();
    jpyUbi.mint(user1, 1000e18);
  }

  function test_mint_revert_bucketCapacityExceeded() public {
    uint128 smallCapacity = 1000e18;

    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', smallCapacity);

    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketCapacityExceeded.selector);
    jpyUbi.mint(user1, smallCapacity + 1);
  }

  function testFuzz_mint_revert_exceedsCapacity(uint128 capacity, uint256 mintAmount) external {
    vm.assume(capacity > 0 && capacity < type(uint128).max);
    vm.assume(mintAmount > capacity);

    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', capacity);

    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketCapacityExceeded.selector);
    jpyUbi.mint(user1, mintAmount);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MINT - SUCCESS CASES
  // ══════════════════════════════════════════════════════════════════════════════

  function test_mint_successAtCapacity() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, DEFAULT_BUCKET_CAPACITY);

    assertEq(jpyUbi.balanceOf(user1), DEFAULT_BUCKET_CAPACITY);
    (, uint256 level) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(level, DEFAULT_BUCKET_CAPACITY);
  }

  function test_mint_successAfterCapacityIncrease() public {
    uint128 initialCapacity = 1000e18;

    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', initialCapacity);

    // Mint to capacity
    vm.prank(facilitator1);
    jpyUbi.mint(user1, initialCapacity);

    // Try to mint more - fails
    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketCapacityExceeded.selector);
    jpyUbi.mint(user1, 1);

    // Increase capacity
    vm.prank(bucketManager);
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, initialCapacity * 2);

    // Now mint succeeds
    vm.prank(facilitator1);
    jpyUbi.mint(user1, initialCapacity);

    assertEq(jpyUbi.balanceOf(user1), initialCapacity * 2);
  }

  function testFuzz_mint_success(uint128 capacity, uint256 mintAmount) external {
    vm.assume(capacity > 0);
    vm.assume(mintAmount > 0 && mintAmount <= capacity);

    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', capacity);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, mintAmount);

    assertEq(jpyUbi.balanceOf(user1), mintAmount);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BURN - ERROR CONDITIONS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_burn_revert_insufficientBalance() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(facilitator1, 1000e18);

    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketLevelExceeded.selector);
    jpyUbi.burn(1001e18);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BURN - SUCCESS CASES
  // ══════════════════════════════════════════════════════════════════════════════

  function test_burn_successReducesBucketLevel() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(facilitator1, 1000e18);

    (, uint256 levelBefore) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(levelBefore, 1000e18);

    vm.prank(facilitator1);
    jpyUbi.burn(500e18);

    (, uint256 levelAfter) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(levelAfter, 500e18);
    assertEq(jpyUbi.balanceOf(facilitator1), 500e18);
  }

  function testFuzz_burn_success(uint256 mintAmount, uint256 burnAmount) external {
    vm.assume(mintAmount > 0 && mintAmount <= DEFAULT_BUCKET_CAPACITY);
    vm.assume(burnAmount > 0 && burnAmount <= mintAmount);

    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(facilitator1, mintAmount);

    vm.prank(facilitator1);
    jpyUbi.burn(burnAmount);

    assertEq(jpyUbi.balanceOf(facilitator1), mintAmount - burnAmount);
    (, uint256 level) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(level, mintAmount - burnAmount);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ACCOUNTING TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_accounting_totalSupplyMatchesSumOfBalances() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, 1000e18);

    vm.prank(facilitator1);
    jpyUbi.mint(user2, 2000e18);

    assertEq(jpyUbi.totalSupply(), 3000e18);
    assertEq(jpyUbi.balanceOf(user1) + jpyUbi.balanceOf(user2), jpyUbi.totalSupply());
  }

  function test_accounting_bucketLevelMatchesMintMinusBurn() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    // Mint 5000
    vm.prank(facilitator1);
    jpyUbi.mint(user1, 5000e18);

    // Transfer 2000 to facilitator and burn
    vm.prank(user1);
    jpyUbi.transfer(facilitator1, 2000e18);

    vm.prank(facilitator1);
    jpyUbi.burn(2000e18);

    // Bucket level should be 3000
    (, uint256 level) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(level, 3000e18);
    assertEq(jpyUbi.totalSupply(), 3000e18);
  }

  function testFuzz_accounting_multipleFacilitators(
    uint128 capacity1,
    uint128 capacity2,
    uint256 mint1,
    uint256 mint2
  ) external {
    vm.assume(capacity1 > 0 && capacity2 > 0);
    vm.assume(mint1 > 0 && mint1 <= capacity1);
    vm.assume(mint2 > 0 && mint2 <= capacity2);

    vm.startPrank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', capacity1);
    jpyUbi.addFacilitator(facilitator2, 'Facilitator 2', capacity2);
    vm.stopPrank();

    vm.prank(facilitator1);
    jpyUbi.mint(user1, mint1);

    vm.prank(facilitator2);
    jpyUbi.mint(user2, mint2);

    // Total supply = sum of mints
    assertEq(jpyUbi.totalSupply(), mint1 + mint2);

    // Each bucket level matches their mints
    (, uint256 level1) = jpyUbi.getFacilitatorBucket(facilitator1);
    (, uint256 level2) = jpyUbi.getFacilitatorBucket(facilitator2);
    assertEq(level1, mint1);
    assertEq(level2, mint2);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MULTIPLE FACILITATORS TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_multipleFacilitators_independentBuckets() public {
    uint128 capacity1 = 1000e18;
    uint128 capacity2 = 500e18;

    vm.startPrank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', capacity1);
    jpyUbi.addFacilitator(facilitator2, 'Facilitator 2', capacity2);
    vm.stopPrank();

    // Facilitator1 can mint to their capacity
    vm.prank(facilitator1);
    jpyUbi.mint(user1, capacity1);

    // Facilitator2 can still mint to their capacity
    vm.prank(facilitator2);
    jpyUbi.mint(user2, capacity2);

    assertEq(jpyUbi.balanceOf(user1), capacity1);
    assertEq(jpyUbi.balanceOf(user2), capacity2);
    assertEq(jpyUbi.totalSupply(), capacity1 + capacity2);
  }

  function test_getFacilitatorsList_returnsAllFacilitators() public {
    vm.startPrank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);
    jpyUbi.addFacilitator(facilitator2, 'Facilitator 2', DEFAULT_BUCKET_CAPACITY);
    vm.stopPrank();

    address[] memory list = jpyUbi.getFacilitatorsList();
    assertEq(list.length, 2);

    bool hasF1 = false;
    bool hasF2 = false;
    for (uint256 i = 0; i < list.length; i++) {
      if (list[i] == facilitator1) hasF1 = true;
      if (list[i] == facilitator2) hasF2 = true;
    }
    assertTrue(hasF1 && hasF2);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // EDGE CASES
  // ══════════════════════════════════════════════════════════════════════════════

  function test_edgeCase_zeroCapacityFacilitator() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Zero Capacity', 0);

    // Cannot mint anything
    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketCapacityExceeded.selector);
    jpyUbi.mint(user1, 1);
  }

  function test_edgeCase_reduceCapacityBelowLevel() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    jpyUbi.mint(user1, 500e18);

    // Reduce capacity below current level - this is allowed
    vm.prank(bucketManager);
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, 100e18);

    // Cannot mint more since level > capacity
    vm.prank(facilitator1);
    vm.expectRevert(JUBCToken.BucketCapacityExceeded.selector);
    jpyUbi.mint(user1, 1);

    // But burns still work
    vm.prank(user1);
    jpyUbi.transfer(facilitator1, 100e18);

    vm.prank(facilitator1);
    jpyUbi.burn(100e18);

    (, uint256 level) = jpyUbi.getFacilitatorBucket(facilitator1);
    assertEq(level, 400e18);
  }

  function test_edgeCase_maxCapacity() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Max Capacity', type(uint128).max);

    // Can mint large amounts
    uint256 largeAmount = 1e30;
    vm.prank(facilitator1);
    jpyUbi.mint(user1, largeAmount);

    assertEq(jpyUbi.balanceOf(user1), largeAmount);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // EVENT EMISSION TESTS
  // ══════════════════════════════════════════════════════════════════════════════

  function test_events_facilitatorAdded() public {
    vm.prank(facilitatorManager);
    vm.expectEmit(true, true, true, true);
    emit FacilitatorAdded(facilitator1, keccak256(abi.encodePacked('Facilitator 1')), DEFAULT_BUCKET_CAPACITY);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);
  }

  function test_events_facilitatorRemoved() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitatorManager);
    vm.expectEmit(true, false, false, false);
    emit FacilitatorRemoved(facilitator1);
    jpyUbi.removeFacilitator(facilitator1);
  }

  function test_events_bucketCapacityUpdated() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    uint128 newCapacity = DEFAULT_BUCKET_CAPACITY * 2;

    vm.prank(bucketManager);
    vm.expectEmit(true, false, false, true);
    emit FacilitatorBucketCapacityUpdated(facilitator1, DEFAULT_BUCKET_CAPACITY, newCapacity);
    jpyUbi.setFacilitatorBucketCapacity(facilitator1, newCapacity);
  }

  function test_events_bucketLevelUpdated() public {
    vm.prank(facilitatorManager);
    jpyUbi.addFacilitator(facilitator1, 'Facilitator 1', DEFAULT_BUCKET_CAPACITY);

    vm.prank(facilitator1);
    vm.expectEmit(true, false, false, true);
    emit FacilitatorBucketLevelUpdated(facilitator1, 0, 1000e18);
    jpyUbi.mint(user1, 1000e18);
  }
}

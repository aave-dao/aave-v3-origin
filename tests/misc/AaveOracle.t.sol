// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {MintableERC20} from '../../src/contracts/mocks/tokens/MintableERC20.sol';
import {MockAggregator} from '../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {PriceOracle} from '../../src/contracts/mocks/oracle/PriceOracle.sol';

contract AaveOracleTest is TestnetProcedures {
  function setUp() public {
    initTestEnvironment();
  }

  function testEmptySource() public {
    address[] memory tokens = new address[](1);

    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address mockTokenAddr = address(mockToken);
    tokens[0] = mockTokenAddr;

    vm.expectRevert();
    contracts.aaveOracle.getAssetPrice(mockTokenAddr);

    vm.expectRevert();
    contracts.aaveOracle.getAssetsPrices(tokens);

    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), address(0));
  }

  function testAddSingleSource() public {
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);
    int256 price = 10e8;

    tokens[0] = address(mockToken);
    sources[0] = address(new MockAggregator(price));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    assertEq(contracts.aaveOracle.getAssetPrice(address(mockToken)), uint256(price));
    assertEq(contracts.aaveOracle.getAssetsPrices(tokens)[0], uint256(price));
    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), sources[0]);
  }

  function testUpdateSingleSource() public {
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);
    int256 price = 99e7;

    tokens[0] = tokenList.usdx;
    sources[0] = address(new MockAggregator(price));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    assertEq(contracts.aaveOracle.getAssetPrice(tokenList.usdx), uint256(price));
    assertEq(contracts.aaveOracle.getAssetsPrices(tokens)[0], uint256(price));
    assertEq(contracts.aaveOracle.getSourceOfAsset(tokenList.usdx), sources[0]);
  }

  function test_revert_setAssetSources_inconsistentParams() public {
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](0);

    tokens[0] = address(mockToken);

    vm.startPrank(poolAdmin);

    vm.expectRevert(bytes(Errors.INCONSISTENT_PARAMS_LENGTH));
    contracts.aaveOracle.setAssetSources(tokens, sources);
    vm.stopPrank();
  }

  function testGetBaseCurrencyPrice() public view {
    assertEq(
      contracts.aaveOracle.getAssetPrice(contracts.aaveOracle.BASE_CURRENCY()),
      contracts.aaveOracle.BASE_CURRENCY_UNIT()
    );
  }

  function test_revert_setAssetSources_wrongCaller() public {
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);

    vm.expectRevert(bytes(Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN));

    contracts.aaveOracle.setAssetSources(tokens, sources);
  }

  function testUpdateSourceBaseCurrency() public {
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);

    sources[0] = address(new MockAggregator(10e7));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    assertEq(contracts.aaveOracle.getAssetPrice(contracts.aaveOracle.BASE_CURRENCY()), 10e7);
    assertEq(
      contracts.aaveOracle.getSourceOfAsset(contracts.aaveOracle.BASE_CURRENCY()),
      sources[0]
    );
  }

  function testGetPriceViaFallbackOracle() public {
    PriceOracle priceOracle = new PriceOracle();
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);

    vm.prank(poolAdmin);
    contracts.aaveOracle.setFallbackOracle(address(priceOracle));

    priceOracle.setAssetPrice(address(mockToken), 300e8);
    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), address(0));
    assertEq(contracts.aaveOracle.getAssetPrice(address(mockToken)), 300e8);
  }

  function testAssetZeroPriceWithoutFallback() public {
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);
    int256 price = 0;

    tokens[0] = address(mockToken);
    sources[0] = address(new MockAggregator(price));

    assertEq(contracts.aaveOracle.getSourceOfAsset(tokens[0]), address(0));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    assertFalse(contracts.aaveOracle.getSourceOfAsset(address(mockToken)) == address(0));
    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), sources[0]);

    vm.expectRevert();
    contracts.aaveOracle.getAssetPrice(address(mockToken));
  }

  function testAssetZeroPriceNonZeroFallback() public {
    PriceOracle priceOracle = new PriceOracle();
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);
    int256 price = 0;
    uint256 fallbackPrice = 2e8;

    tokens[0] = address(mockToken);
    sources[0] = address(new MockAggregator(price));

    priceOracle.setAssetPrice(tokens[0], fallbackPrice);

    assertEq(contracts.aaveOracle.getSourceOfAsset(tokens[0]), address(0));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    vm.prank(poolAdmin);
    contracts.aaveOracle.setFallbackOracle(address(priceOracle));

    assertFalse(contracts.aaveOracle.getSourceOfAsset(address(mockToken)) == address(0));
    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), sources[0]);
    assertEq(contracts.aaveOracle.getAssetPrice(address(mockToken)), fallbackPrice);
  }

  function testAssetZeroPriceAndZeroFallbackPrice() public {
    PriceOracle priceOracle = new PriceOracle();
    MintableERC20 mockToken = new MintableERC20('X', 'X', 18);
    address[] memory tokens = new address[](1);
    address[] memory sources = new address[](1);
    int256 price = 0;
    uint256 fallbackPrice = 0;

    tokens[0] = address(mockToken);
    sources[0] = address(new MockAggregator(price));

    priceOracle.setAssetPrice(tokens[0], fallbackPrice);

    assertEq(contracts.aaveOracle.getSourceOfAsset(tokens[0]), address(0));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setAssetSources(tokens, sources);

    vm.prank(poolAdmin);
    contracts.aaveOracle.setFallbackOracle(address(priceOracle));

    assertFalse(contracts.aaveOracle.getSourceOfAsset(address(mockToken)) == address(0));
    assertEq(contracts.aaveOracle.getSourceOfAsset(address(mockToken)), sources[0]);
    assertEq(contracts.aaveOracle.getAssetPrice(address(mockToken)), fallbackPrice);
  }

  function testUpdateFallbackOracle() public {
    PriceOracle priceOracle = new PriceOracle();
    assertEq(contracts.aaveOracle.getFallbackOracle(), address(0));

    vm.prank(poolAdmin);
    contracts.aaveOracle.setFallbackOracle(address(priceOracle));

    assertEq(contracts.aaveOracle.getFallbackOracle(), address(priceOracle));
    assertFalse(contracts.aaveOracle.getFallbackOracle() == address(0));
  }
}

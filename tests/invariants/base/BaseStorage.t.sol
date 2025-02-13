// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {ILendingHandler} from '../handlers/interfaces/ILendingHandler.sol';
import {IBorrowingHandler} from '../handlers/interfaces/IBorrowingHandler.sol';
import {ILiquidationHandler} from '../handlers/interfaces/ILiquidationHandler.sol';
import {IPoolHandler} from '../handlers/interfaces/IPoolHandler.sol';
import {IATokenHandler} from '../handlers/interfaces/IATokenHandler.sol';
import {IFlashLoanHandler} from '../handlers/interfaces/IFlashLoanHandler.sol';
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

// Mock Contracts
import {TestnetERC20} from 'src/contracts/mocks/testnet-helpers/TestnetERC20.sol';

// Test Contracts
import 'src/deployments/interfaces/IMarketReportTypes.sol';
import {MockAggregatorSetPrice} from '../utils/mocks/MockAggregatorSetPrice.sol';

// Utils
import {Actor} from '../utils/Actor.sol';
import {WETH9} from 'src/contracts/dependencies/weth/WETH9.sol';

/// @notice BaseStorage contract for all test contracts, works in tandem with BaseTest
abstract contract BaseStorage {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       CONSTANTS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  uint256 constant MAX_TOKEN_AMOUNT = 1e29;

  uint256 constant ONE_DAY = 1 days;
  uint256 constant ONE_MONTH = ONE_YEAR / 12;
  uint256 constant ONE_YEAR = 365 days;

  uint256 internal constant NUMBER_OF_ACTORS = 3;
  uint256 internal constant INITIAL_ETH_BALANCE = 1e26;
  uint256 internal constant INITIAL_COLL_BALANCE = 1e21;

  uint256 internal constant MAX_GRACE_PERIOD = 4 hours;

  // HF CHANGING ACTIONS

  /// @notice Actions that cannot decrease the hf
  bytes4[] nonDecreasingHfActions = [
    ILendingHandler.supply.selector,
    IBorrowingHandler.repay.selector,
    IBorrowingHandler.repayWithATokens.selector,
    ILiquidationHandler.liquidationCall.selector
  ];

  /// @notice Actions that cannot increase the hf
  bytes4[] nonIncreasingHfActions = [
    ILendingHandler.withdraw.selector,
    IBorrowingHandler.borrow.selector,
    IFlashLoanHandler.flashLoan.selector,
    IFlashLoanHandler.flashLoanSimple.selector
  ];

  // HF TRANSITION ACTIONS

  /// @notice Actions that can leave user hf unsafe if it was already unsafe
  bytes4[] hfUnsafeAfterActions = [
    IATokenHandler.transfer.selector, /// @dev even though transfer & transferFrom requires a health check for sender, since is not applied in certain situations, it is checked in HSPOST
    IATokenHandler.transferFrom.selector,
    ILendingHandler.supply.selector,
    ILendingHandler.withdraw.selector, /// @dev even though withdraw requires a health check for sender, since is not applied in certain situations, it is checked in HSPOST
    IBorrowingHandler.repay.selector,
    IBorrowingHandler.repayWithATokens.selector,
    IPoolHandler.setUserEMode.selector, /// @dev even though setUserEMode requires a health check for sender, since is not applied in certain situations, it is checked in HSPOST
    IBorrowingHandler.setUserUseReserveAsCollateral.selector,
    IFlashLoanHandler.flashLoan.selector,
    IFlashLoanHandler.flashLoanSimple.selector,
    ILiquidationHandler.liquidationCall.selector // TODO
  ];

  /// @notice Actions that can operate when user hf is unsafe
  bytes4[] hfUnsafeBeforeActions = [
    IATokenHandler.transfer.selector,
    IATokenHandler.transferFrom.selector,
    ILendingHandler.supply.selector,
    ILendingHandler.withdraw.selector,
    IBorrowingHandler.repay.selector,
    IBorrowingHandler.repayWithATokens.selector,
    IBorrowingHandler.setUserUseReserveAsCollateral.selector,
    IFlashLoanHandler.flashLoan.selector,
    IFlashLoanHandler.flashLoanSimple.selector,
    IPoolHandler.setUserEMode.selector,
    ILiquidationHandler.liquidationCall.selector // TODO
  ];

  mapping(bytes4 => bool) isNonDecreasingHfAction;
  mapping(bytes4 => bool) isNonIncreasingHfAction;

  mapping(bytes4 => bool) isHfUnsafeAfterAction;
  mapping(bytes4 => bool) isHfUnsafeBeforeAction;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTORS                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice Stores the actor during a handler call
  Actor internal actor;

  /// @notice Mapping of fuzzer user addresses to actors
  mapping(address => Actor) internal actors;

  /// @notice Array of all actor addresses
  address[] internal actorAddresses;

  /// @notice The pool admin is set to this contract, the Tester contract
  address internal poolAdmin = address(this);

  /// @notice The address that is targeted when executing an action
  address internal senderActor;

  /// @notice The address that is targeted when executing an action
  address internal receiverActor;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       SUITE STORAGE                                       //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  // PROTOCOL CONTRACTS
  ContractsReport internal contracts;

  IPool internal pool;

  // ASSETS
  TestnetERC20 internal usdx;
  TestnetERC20 internal wbtc;
  WETH9 internal weth;

  TokenList internal tokenList;

  // MOCKS
  MockAggregatorSetPrice internal mockPriceAggregatorUSDX;
  MockAggregatorSetPrice internal mockPriceAggregatorWBTC;
  MockAggregatorSetPrice internal mockPriceAggregatorWETH;

  address internal flashLoanReceiver;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       EXTRA VARIABLES                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice Array of base assets for the suite
  address[] internal baseAssets;

  /// @notice Array of Atokens of the suite
  address[] internal aTokens;

  /// @notice Array of DebtTokens of the suite
  address[] internal debtTokens;

  /// @notice Array of the custom mock price aggregators of the suite
  address[] internal priceAggregators;

  /// @notice Mappinng from asset to protocol tokens
  mapping(address => ProtocolTokens) internal protocolTokens;

  /// @notice Target asset for the test run
  address internal targetAsset;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          STRUCTS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  struct TokenList {
    address wbtc;
    address weth;
    address usdx;
  }

  struct ProtocolTokens {
    address aTokenAddress;
    address variableDebtTokenAddress;
    uint256 id;
  }
}

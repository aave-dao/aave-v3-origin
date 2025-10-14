// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Context} from '../../../dependencies/openzeppelin/contracts/Context.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {IACLManager} from '../../../interfaces/IACLManager.sol';
import {DelegationMode} from './DelegationMode.sol';

/**
 * @title IncentivizedERC20
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 */
abstract contract IncentivizedERC20 is Context, IERC20Detailed {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  /**
   * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   * @param allowance Amount of tokens a `spender` is allowed to operate with.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin() {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(_msgSender()), Errors.CallerNotPoolAdmin());
    _;
  }

  /**
   * @dev Only pool can call functions marked by this modifier.
   */
  modifier onlyPool() {
    require(_msgSender() == address(POOL), Errors.CallerMustBePool());
    _;
  }

  /**
   * @dev UserState - additionalData is a flexible field.
   * ATokens and VariableDebtTokens use this field store the index of the
   * user's last supply/withdrawal/borrow/repayment.
   */
  struct UserState {
    uint120 balance;
    DelegationMode delegationMode;
    uint128 additionalData;
  }
  // Map of users address and their state data (userAddress => userStateData)
  mapping(address => UserState) internal _userState;

  // Map of allowances (delegator => delegatee => allowanceAmount)
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 internal _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  // @dev deprecated on v3.4.0, replaced with immutable REWARDS_CONTROLLER
  IAaveIncentivesController internal __deprecated_incentivesController;
  IPoolAddressesProvider internal immutable _addressesProvider;
  IPool public immutable POOL;
  /**
   * @notice Returns the address of the Incentives Controller contract
   * @return The address of the Incentives Controller
   */
  IAaveIncentivesController public immutable REWARDS_CONTROLLER;

  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name_ The name of the token
   * @param symbol_ The symbol of the token
   * @param decimals_ The number of decimals of the token
   * @param rewardsController The address of the rewards controller contract
   */
  constructor(
    IPool pool,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address rewardsController
  ) {
    _addressesProvider = pool.ADDRESSES_PROVIDER();
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    POOL = pool;
    REWARDS_CONTROLLER = IAaveIncentivesController(rewardsController);
  }

  /// @inheritdoc IERC20Detailed
  function name() public view override returns (string memory) {
    return _name;
  }

  /// @inheritdoc IERC20Detailed
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /// @inheritdoc IERC20Detailed
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /// @inheritdoc IERC20
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _userState[account].balance;
  }

  /**
   * @notice Returns the address of the Incentives Controller contract
   * @return The address of the Incentives Controller
   */
  function getIncentivesController() external view virtual returns (IAaveIncentivesController) {
    return REWARDS_CONTROLLER;
  }

  /// @inheritdoc IERC20
  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    uint120 castAmount = amount.toUint120();
    _transfer(_msgSender(), recipient, castAmount);
    return true;
  }

  /// @inheritdoc IERC20
  function allowance(
    address owner,
    address spender
  ) external view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /// @inheritdoc IERC20
  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /// @inheritdoc IERC20
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external virtual override returns (bool) {
    uint120 castAmount = amount.toUint120();
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - castAmount);
    _transfer(sender, recipient, castAmount);
    return true;
  }

  /**
   * @notice Increases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param addedValue The amount being added to the allowance
   * @return `true`
   */
  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @notice Decreases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param subtractedValue The amount being subtracted to the allowance
   * @return `true`
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
   *
   * Revert if not enough allowance is available.
   *
   * @param owner The owner of the tokens
   * @param spender The user allowed to spend on behalf of owner
   * @param amount The minimum amount being consumed from the allowance
   * @param correctedAmount The maximum amount being consumed from the allowance
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount,
    uint256 correctedAmount
  ) internal virtual {
    uint256 currentAllowance = _allowances[owner][spender];
    if (currentAllowance < amount) {
      revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
    }

    uint256 consumption = currentAllowance >= correctedAmount ? correctedAmount : currentAllowance;
    _approve(owner, spender, currentAllowance - consumption);
  }

  /**
   * @notice Transfers tokens between two users and apply incentives if defined.
   * @param sender The source address
   * @param recipient The destination address
   * @param amount The amount getting transferred
   */
  function _transfer(address sender, address recipient, uint120 amount) internal virtual {
    uint120 oldSenderBalance = _userState[sender].balance;
    _userState[sender].balance = oldSenderBalance - amount;
    uint120 oldRecipientBalance = _userState[recipient].balance;
    _userState[recipient].balance = oldRecipientBalance + amount;

    if (address(REWARDS_CONTROLLER) != address(0)) {
      uint256 currentTotalSupply = _totalSupply;
      REWARDS_CONTROLLER.handleAction(sender, currentTotalSupply, oldSenderBalance);
      if (sender != recipient) {
        REWARDS_CONTROLLER.handleAction(recipient, currentTotalSupply, oldRecipientBalance);
      }
    }
  }

  /**
   * @notice Approve `spender` to use `amount` of `owner`s balance
   * @param owner The address owning the tokens
   * @param spender The address approved for spending
   * @param amount The amount of tokens to approve spending of
   */
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @notice Update the name of the token
   * @param newName The new name for the token
   */
  function _setName(string memory newName) internal {
    _name = newName;
  }

  /**
   * @notice Update the symbol for the token
   * @param newSymbol The new symbol for the token
   */
  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  /**
   * @notice Update the number of decimals for the token
   * @param newDecimals The new number of decimals for the token
   */
  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {VersionedInitializable} from '../../misc/aave-upgradeability/VersionedInitializable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {IAToken} from '../../interfaces/IAToken.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';
import {IInitializableAToken} from '../../interfaces/IInitializableAToken.sol';
import {ScaledBalanceTokenBase} from './base/ScaledBalanceTokenBase.sol';
import {IncentivizedERC20} from './base/IncentivizedERC20.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {TokenMath} from '../libraries/helpers/TokenMath.sol';

/**
 * @title Aave ERC20 AToken
 * @author Aave
 * @notice Implementation of the interest bearing token for the Aave protocol
 */
abstract contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, IAToken {
  using TokenMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  address public immutable TREASURY;

  address internal _deprecated_treasury;
  address internal _underlyingAsset;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   * @param rewardsController The address of the rewards controller contract
   * @param treasury The address of the treasury. This is where accrued interest is sent.
   */
  constructor(
    IPool pool,
    address rewardsController,
    address treasury
  ) ScaledBalanceTokenBase(pool, 'ATOKEN_IMPL', 'ATOKEN_IMPL', 0, rewardsController) EIP712Base() {
    require(treasury != address(0), Errors.ZeroAddressNotValid());
    TREASURY = treasury;
  }

  /// @inheritdoc IInitializableAToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) public virtual;

  /// @inheritdoc IAToken
  function mint(
    address caller,
    address onBehalfOf,
    uint256 scaledAmount,
    uint256 index
  ) external virtual override onlyPool returns (bool) {
    return
      _mintScaled({
        caller: caller,
        onBehalfOf: onBehalfOf,
        amountScaled: scaledAmount,
        index: index,
        getTokenBalance: TokenMath.getATokenBalance
      });
  }

  /// @inheritdoc IAToken
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 scaledAmount,
    uint256 index
  ) external virtual override onlyPool returns (bool) {
    bool zeroBalanceAfterBurn = _burnScaled({
      user: from,
      target: receiverOfUnderlying,
      amountScaled: scaledAmount,
      index: index,
      getTokenBalance: TokenMath.getATokenBalance
    });

    if (receiverOfUnderlying != address(this)) {
      IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);
    }
    return zeroBalanceAfterBurn;
  }

  /// @inheritdoc IAToken
  function mintToTreasury(uint256 scaledAmount, uint256 index) external virtual override onlyPool {
    if (scaledAmount == 0) {
      return;
    }
    _mintScaled({
      caller: address(POOL),
      onBehalfOf: TREASURY,
      amountScaled: scaledAmount,
      index: index,
      getTokenBalance: TokenMath.getATokenBalance
    });
  }

  /// @inheritdoc IAToken
  function transferOnLiquidation(
    address from,
    address to,
    uint256 amount,
    uint256 scaledAmount,
    uint256 index
  ) external virtual override onlyPool {
    _transfer({
      sender: from,
      recipient: to,
      amount: amount,
      scaledAmount: scaledAmount.toUint120(),
      index: index
    });
  }

  /// @inheritdoc IERC20
  function balanceOf(
    address user
  ) public view virtual override(IncentivizedERC20, IERC20) returns (uint256) {
    return
      super.balanceOf(user).getATokenBalance(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override(IncentivizedERC20, IERC20) returns (uint256) {
    return super.totalSupply().getATokenBalance(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  /// @inheritdoc IAToken
  function RESERVE_TREASURY_ADDRESS() external view override returns (address) {
    return TREASURY;
  }

  /// @inheritdoc IAToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
  }

  /// @inheritdoc IAToken
  function transferUnderlyingTo(address target, uint256 amount) external virtual override onlyPool {
    IERC20(_underlyingAsset).safeTransfer(target, amount);
  }

  /// @inheritdoc IAToken
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), Errors.ZeroAddressNotValid());
    //solium-disable-next-line
    require(block.timestamp <= deadline, Errors.InvalidExpiration());
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR(),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );
    require(owner == ECDSA.recover(digest, v, r, s), Errors.InvalidSignature());
    _nonces[owner] = currentValidNonce + 1;
    _approve(owner, spender, value);
  }

  /// @inheritdoc IERC20
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external virtual override(IERC20, IncentivizedERC20) returns (bool) {
    uint256 index = POOL.getReserveNormalizedIncome(_underlyingAsset);
    uint256 scaledBalanceOfSender = super.balanceOf(sender);
    _spendAllowance(
      sender,
      _msgSender(),
      amount,
      // This comment explains the logic behind the allowance spent calculation.
      //
      // Problem:
      // Simply decreasing the allowance by the input `amount` is not ideal for scaled-balance tokens.
      // Due to rounding, the actual decrease in the sender's balance (`amount_out`) can be slightly
      // larger than the input `amount`.
      //
      // Definitions:
      // - `amount`: The unscaled amount to be transferred, passed as the `amount` argument.
      // - `amount_out`: The actual unscaled amount deducted from the sender's balance.
      // - `amount_in`: The actual unscaled amount added to the recipient's balance.
      // - `allowance_spent`: The unscaled amount deducted from the spender's allowance. Equivalent to `amount_out`.
      // - `amount_logged`: The amount logged in the `Transfer` event. Equivalent to `amount`.
      //
      // Solution:
      // To fix this, `allowance_spent` must be exactly equal to `amount_out`.
      // We calculate `amount_out` precisely by simulating the effect of the transfer on the sender's balance.
      // By passing `amount_out` to `_spendAllowance`, we ensure `allowance_spent` is as close as possible to `amount_out`.
      // `amount_logged` is equal to `amount`. `amount_in` is the actual balance increase for the recipient, which is >= `amount` due to rounding.
      //
      // Backward Compatibility & Guarantees:
      // This implementation is backward-compatible and secure. The `_spendAllowance` function has a critical feature:
      // 1. It REQUIRES the allowance to be >= `amount` (the user's requested transfer amount).
      // 2. The amount consumed from the allowance is `amount_out`, but it is capped at the `currentAllowance`.
      // This means if a user has an allowance of 100 wei and calls `transferFrom` with an `amount` of 100, the call will succeed
      // even if the calculated `amount_out` is 101 wei. In that specific scenario, the allowance consumed will be 100 wei (since that is the `currentAllowance`),
      // and the transaction will not revert. But if the allowance is 101 wei, then the allowance consumed will be 101 wei.
      //
      // uint256 amount_in = amount.getATokenTransferScaledAmount(index);
      // uint256 amount_out = balanceBefore - balanceAfter = scaledBalanceOfSender.getATokenBalance(index) - (scaledBalanceOfSender - amount_in).getATokenBalance(index);
      // Due to limitations of the solidity compiler, the calculation is inlined for gas efficiency.
      scaledBalanceOfSender.getATokenBalance(index) -
        (scaledBalanceOfSender - amount.getATokenTransferScaledAmount(index)).getATokenBalance(
          index
        )
    );
    _transfer(sender, recipient, amount.toUint120());
    return true;
  }

  /**
   * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   */
  function _transfer(address from, address to, uint120 amount) internal virtual override {
    address underlyingAsset = _underlyingAsset;

    uint256 index = POOL.getReserveNormalizedIncome(underlyingAsset);

    uint256 scaledBalanceFromBefore = super.balanceOf(from);
    uint256 scaledBalanceToBefore = super.balanceOf(to);
    uint256 scaledAmount = uint256(amount).getATokenTransferScaledAmount(index);

    _transfer({
      sender: from,
      recipient: to,
      amount: amount,
      scaledAmount: scaledAmount.toUint120(),
      index: index
    });

    POOL.finalizeTransfer({
      asset: underlyingAsset,
      from: from,
      to: to,
      scaledAmount: scaledAmount,
      scaledBalanceFromBefore: scaledBalanceFromBefore,
      scaledBalanceToBefore: scaledBalanceToBefore
    });
  }

  /**
   * @notice Implements the basic logic to transfer scaled balance tokens between two users
   * @dev It emits a mint event with the interest accrued per user
   * @param sender The source address
   * @param recipient The destination address
   * @param amount The amount getting transferred
   * @param scaledAmount The scaled amount getting transferred
   * @param index The next liquidity index of the reserve
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount,
    uint120 scaledAmount,
    uint256 index
  ) internal virtual {
    uint256 senderScaledBalance = super.balanceOf(sender);
    uint256 senderBalanceIncrease = senderScaledBalance.getATokenBalance(index) -
      senderScaledBalance.getATokenBalance(_userState[sender].additionalData);

    uint256 recipientScaledBalance = super.balanceOf(recipient);
    uint256 recipientBalanceIncrease = recipientScaledBalance.getATokenBalance(index) -
      recipientScaledBalance.getATokenBalance(_userState[recipient].additionalData);

    _userState[sender].additionalData = index.toUint128();
    _userState[recipient].additionalData = index.toUint128();

    super._transfer(sender, recipient, scaledAmount);

    if (senderBalanceIncrease > 0) {
      emit Transfer(address(0), sender, senderBalanceIncrease);
      emit Mint(_msgSender(), sender, senderBalanceIncrease, senderBalanceIncrease, index);
    }

    if (sender != recipient && recipientBalanceIncrease > 0) {
      emit Transfer(address(0), recipient, recipientBalanceIncrease);
      emit Mint(_msgSender(), recipient, recipientBalanceIncrease, recipientBalanceIncrease, index);
    }

    emit Transfer(sender, recipient, amount);
    emit BalanceTransfer(sender, recipient, scaledAmount, index);
  }

  /**
   * @dev Overrides the base function to fully implement IAToken
   * @dev see `EIP712Base.DOMAIN_SEPARATOR()` for more detailed documentation
   */
  function DOMAIN_SEPARATOR() public view override(IAToken, EIP712Base) returns (bytes32) {
    return super.DOMAIN_SEPARATOR();
  }

  /**
   * @dev Overrides the base function to fully implement IAToken
   * @dev see `EIP712Base.nonces()` for more detailed documentation
   */
  function nonces(address owner) public view override(IAToken, EIP712Base) returns (uint256) {
    return super.nonces(owner);
  }

  /// @inheritdoc EIP712Base
  function _EIP712BaseId() internal view override returns (string memory) {
    return name();
  }

  /// @inheritdoc IAToken
  function rescueTokens(address token, address to, uint256 amount) external override onlyPoolAdmin {
    require(token != _underlyingAsset, Errors.UnderlyingCannotBeRescued());
    IERC20(token).safeTransfer(to, amount);
  }
}

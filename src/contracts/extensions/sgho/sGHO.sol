// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {ERC4626Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {WadRayMath} from '../../../contracts/protocol/libraries/math/WadRayMath.sol';
import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import {IsGHO} from './interfaces/IsGHO.sol';
import {ERC20Upgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol';

/**
 * @title sGHO Token
 * @author Luigy-Lemon @kpk
 * @notice sGHO is an ERC4626 vault that allows users to deposit GHO and earn yield.
 * @dev This contract implements the ERC4626 standard for tokenized vaults, where the underlying asset is GHO.
 * It also includes functionalities for yield generation based on a target rate, and administrative roles for managing the contract.
 */
contract sGHO is Initializable, ERC4626Upgradeable, ERC20PermitUpgradeable, IsGHO {
  using WadRayMath for uint256;
  using Math for uint256;

  address public gho;
  IAccessControl internal aclManager;

  uint256 public targetRate;
  uint256 public maxTargetRate;
  uint256 public yieldIndex;
  uint256 public lastUpdate;
  uint256 internal constant RATE_PRECISION = 1e10;
  uint256 internal constant ONE_YEAR = 365 days;

  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';
  bytes32 public constant YIELD_MANAGER_ROLE = 'YIELD_MANAGER';

  // --- EIP712 niceties ---
  uint256 public deploymentChainId;
  string public constant VERSION = '1';

  /**
   * @dev Disable initializers on the implementation contract
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializer for the sGHO vault.
   * @param _gho       Address of the underlying GHO token.
   * @param _aclmanager Address of the Aave ACL Manager.
   * @param _maxTargetRate The maximum allowable target rate.
   */
  function initialize(
    address _gho,
    address _aclmanager,
    uint256 _maxTargetRate
  ) public payable initializer {
    __ERC20_init('sGHO', 'sGHO');
    __ERC4626_init(IERC20(_gho));
    __ERC20Permit_init('sGHO');

    gho = _gho;
    aclManager = IAccessControl(_aclmanager);
    maxTargetRate = _maxTargetRate;

    deploymentChainId = block.chainid;
    yieldIndex = WadRayMath.RAY;
    lastUpdate = block.timestamp;
  }

  /**
   * @notice The receive function is implemented to reject direct Ether transfers to the contract.
   * @dev sGHO does not handle ETH directly. All deposits must be made in the GHO token.
   */
  receive() external payable {
    revert NoEthAllowed();
  }

  /**
   * @notice Modifier to check if the contract has been initialized.
   * @dev Throws if the `initialize` function has not been called.
   */
  modifier isInitialized() {
    if (_getInitializedVersion() == 0) {
      revert NotInitialized();
    }
    _;
  }

  /**
   * @notice Modifier that restricts a function to be called only by an address with the YIELD_MANAGER role.
   * @dev See {_onlyYieldManager}.
   */
  modifier onlyYieldManager() {
    if (_onlyYieldManager() == false) {
      revert OnlyYieldManager();
    }
    _;
  }

  /**
   * @notice Modifier that restricts a function to be called only by an address with the FUNDS_ADMIN role.
   * @dev See {_onlyFundsAdmin}.
   */
  modifier onlyFundsAdmin() {
    if (_onlyFundsAdmin() == false) {
      revert OnlyFundsAdmin();
    }
    _;
  }

  // --- Approve by signature ---
  /**
   * @notice Overload of the `permit` function that accepts v, r, and s as separate arguments.
   * @dev This is a convenience function for platforms that do not handle the single `bytes` signature format.
   * @param owner The address of the user who owns the tokens.
   * @param spender The address of the spender to be approved.
   * @param value The amount of tokens to approve.
   * @param deadline The deadline after which the signature is no longer valid.
   * @param v The v component of the signature.
   * @param r The r component of the signature.
   * @param s The s component of the signature.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override(IsGHO, ERC20PermitUpgradeable) {
    super.permit(owner, spender, value, deadline, v, r, s);
  }

  /**
   * @dev See {IERC20Permit-nonces}.
   */
  function nonces(address owner) public view virtual override(ERC20PermitUpgradeable) returns (uint256) {
    return super.nonces(owner);
  }

  /**
   * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
   */
  function DOMAIN_SEPARATOR() external view virtual override returns (bytes32) {
    return _domainSeparatorV4();
  }

  function decimals() public view virtual override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
    return super.decimals();
  }

  // --- ERC4626 Logic ---

  /**
   * @notice Returns the maximum amount of GHO that can be withdrawn by an owner.
   * @dev This is the minimum of the amount of shares the owner has and the total GHO balance of the contract.
   * @param owner The address of the user who owns the shares.
   * @return The maximum amount of GHO that can be withdrawn.
   */
  function maxWithdraw(address owner) public view override(ERC4626Upgradeable) returns (uint256) {
    return Math.min(super.maxWithdraw(owner), IERC20(gho).balanceOf(address(this)));
  }

  /**
   * @notice Returns the maximum amount of sGHO shares that can be redeemed by an owner.
   * @dev This is the minimum of the owner's share balance and the number of shares corresponding to the contract's total GHO balance.
   * @param owner The address of the user who owns the shares.
   * @return The maximum amount of sGHO shares that can be redeemed.
   */
  function maxRedeem(address owner) public view override(ERC4626Upgradeable) returns (uint256) {
    return Math.min(
      super.maxRedeem(owner),
      convertToShares(IERC20(gho).balanceOf(address(this)))
    );
  }

  /**
   * @notice Deposits GHO into the vault and mints sGHO shares to the receiver.
   * @dev The yield index is updated before the deposit to ensure correct share calculation.
   * @param assets The amount of GHO to deposit.
   * @param receiver The address that will receive the sGHO shares.
   * @return The amount of sGHO shares minted.
   */
  function deposit(uint256 assets, address receiver) public override(ERC4626Upgradeable) returns (uint256) {
    uint256 maxAssets = maxDeposit(receiver);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
    }

    _updateYieldIndex();
    uint256 shares = previewDeposit(assets);
    _deposit(_msgSender(), receiver, assets, shares);

    return shares;
  }

  /**
   * @notice Mints sGHO shares to the receiver by depositing a corresponding amount of GHO.
   * @dev The yield index is updated before the mint to ensure correct asset calculation.
   * @param shares The amount of sGHO shares to mint.
   * @param receiver The address that will receive the sGHO shares.
   * @return The amount of GHO deposited.
   */
  function mint(uint256 shares, address receiver) public override(ERC4626Upgradeable) returns (uint256) {
    uint256 maxShares = maxMint(receiver);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
    }

    _updateYieldIndex();
    uint256 assets = previewMint(shares);

    _deposit(_msgSender(), receiver, assets, shares);

    return assets;
  }

  /**
   * @notice Withdraws GHO from the vault by burning sGHO shares from the owner.
   * @dev The yield index is updated before the withdrawal.
   * @param assets The amount of GHO to withdraw.
   * @param receiver The address that will receive the GHO.
   * @param owner The address from which to burn sGHO shares.
   * @return The amount of sGHO shares burned.
   */
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override(ERC4626Upgradeable) returns (uint256) {
    uint256 maxAssets = maxWithdraw(owner);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
    }

    _updateYieldIndex();
    uint256 shares = previewWithdraw(assets);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    return shares;
  }

  /**
   * @notice Redeems a specific amount of sGHO shares for GHO.
   * @dev The yield index is updated before the redemption.
   * @param shares The amount of sGHO shares to redeem.
   * @param receiver The address that will receive the GHO.
   * @param owner The address from which to burn sGHO shares.
   * @return The amount of GHO received.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override(ERC4626Upgradeable) returns (uint256) {
    uint256 maxShares = maxRedeem(owner);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
    }

    _updateYieldIndex();
    uint256 assets = previewRedeem(shares);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    return assets;
  }

  /**
   * @notice Returns the total amount of GHO managed by the vault.
   * @dev This is calculated based on the total supply of sGHO and the current yield index.
   * @return The total amount of GHO assets.
   */
  function totalAssets() public view override(ERC4626Upgradeable) returns (uint256) {
    return _convertToAssets(totalSupply(), Math.Rounding.Floor);
  }

  /**
   * @notice Converts a GHO asset amount to a sGHO share amount based on the current yield index.
   * @dev Overrides the standard ERC4626 implementation to use the custom yield-based conversion.
   * @param assets The amount of GHO assets.
   * @param rounding The rounding direction to use.
   * @return The corresponding amount of sGHO shares.
   */
  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    uint256 currentYieldIndex = _getCurrentYieldIndex();
    if (currentYieldIndex == 0) return 0;
    return assets.mulDiv(WadRayMath.RAY, currentYieldIndex, rounding);
  }

  /**
   * @notice Converts a sGHO share amount to a GHO asset amount based on the current yield index.
   * @dev Overrides the standard ERC4626 implementation to use the custom yield-based conversion.
   * @param shares The amount of sGHO shares.
   * @param rounding The rounding direction to use.
   * @return The corresponding amount of GHO assets.
   */
  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    uint256 currentYieldIndex = _getCurrentYieldIndex();
    return shares.mulDiv(currentYieldIndex, WadRayMath.RAY, rounding);
  }

  /**
   * @notice Calculates the current yield index, including yield accrued since the last update.
   * @dev This is a view function and does not modify state. It's used for previews.
   * @return The current yield index.
   */
  function _getCurrentYieldIndex() internal view returns (uint256) {
    if (targetRate == 0) return yieldIndex;

    uint256 timeSinceLastUpdate = block.timestamp - lastUpdate;
    if (timeSinceLastUpdate == 0) return yieldIndex;

    // Calculate the rate per second based on the target rate
    uint256 annualRateRay = targetRate.rayMul(WadRayMath.RAY);
    uint256 currentRatePerSecond = annualRateRay.rayDiv(ONE_YEAR);

    // Calculate the index change per second
    uint256 currentIndexChangePerSecond = yieldIndex.rayMul(currentRatePerSecond).rayDiv(10000);

    uint256 yieldIndexChange = currentIndexChangePerSecond.rayMul(timeSinceLastUpdate);

    return yieldIndex + yieldIndexChange;
  }

  /**
   * @notice Updates the yield index to accrue yield up to the current timestamp.
   * @dev This function modifies state and is called before any operation that depends on the yield index.
   */
  function _updateYieldIndex() internal {
    uint256 newYieldIndex = _getCurrentYieldIndex();
    if (newYieldIndex != yieldIndex) {
      yieldIndex = newYieldIndex;
      lastUpdate = block.timestamp;
    }
  }

  /**
   * @inheritdoc IsGHO
   */
  function vaultAPR() external view returns (uint256) {
    return targetRate;
  }

  /**
   * @inheritdoc IsGHO
   */
  function setTargetRate(uint256 newRate) public onlyYieldManager {
    // Update the yield index before changing the rate to ensure proper accrual
    if (newRate > maxTargetRate) {
      revert RateMustBeLessThanMaxRate();
    }
    _updateYieldIndex();
    targetRate = newRate;
    emit TargetRateUpdated(newRate);
  }

  /**
   * @inheritdoc IsGHO
   */
  function rescueERC20(address erc20Token, address to, uint256 amount) external onlyFundsAdmin {
    if (erc20Token == gho) {
      revert CannotRescueGHO();
    }
    uint256 max = IERC20(erc20Token).balanceOf(address(this));
    amount = max > amount ? amount : max;
    IERC20(erc20Token).transfer(to, amount);
    emit ERC20Rescued(msg.sender, erc20Token, to, amount);
  }

  /**
   * @notice Internal view function to check if the caller has the FUNDS_ADMIN role.
   * @return A boolean indicating if the caller is a Funds Admin.
   */
  function _onlyFundsAdmin() internal view returns (bool) {
    return aclManager.hasRole(FUNDS_ADMIN_ROLE, msg.sender);
  }

  /**
   * @notice Internal view function to check if the caller has the YIELD_MANAGER role.
   * @return A boolean indicating if the caller is a Yield Manager.
   */
  function _onlyYieldManager() internal view returns (bool) {
    return aclManager.hasRole(YIELD_MANAGER_ROLE, msg.sender);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC4626Upgradeable, Math, IERC4626} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {SafeERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';

import {IPool, IPoolAddressesProvider} from '../../interfaces/IPool.sol';
import {IAaveOracle} from '../../interfaces/IAaveOracle.sol';
import {DataTypes, ReserveConfiguration} from '../../protocol/libraries/configuration/ReserveConfiguration.sol';

import {IAToken} from './interfaces/IAToken.sol';
import {IERC4626StataToken} from './interfaces/IERC4626StataToken.sol';

/**
 * @title ERC4626StataTokenUpgradeable
 * @notice Wrapper smart contract that allows to deposit tokens on the Aave protocol and receive
 * a token which balance doesn't increase automatically, but uses an ever-increasing exchange rate.
 * @dev ERC20 extension, so ERC20 initialization should be done by the children contract/s
 * @author BGD labs
 */
abstract contract ERC4626StataTokenUpgradeable is ERC4626Upgradeable, IERC4626StataToken {
  using Math for uint256;

  /// @custom:storage-location erc7201:aave-dao.storage.ERC4626StataToken
  struct ERC4626StataTokenStorage {
    IERC20 _aToken;
  }

  // keccak256(abi.encode(uint256(keccak256("aave-dao.storage.ERC4626StataToken")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant ERC4626StataTokenStorageLocation =
    0x55029d3f54709e547ed74b2fc842d93107ab1490ab7555dd9dd0bf6451101900;

  function _getERC4626StataTokenStorage()
    private
    pure
    returns (ERC4626StataTokenStorage storage $)
  {
    assembly {
      $.slot := ERC4626StataTokenStorageLocation
    }
  }

  uint256 public constant RAY = 1e27;

  IPool public immutable POOL;
  IPoolAddressesProvider public immutable POOL_ADDRESSES_PROVIDER;

  constructor(IPool pool) {
    POOL = pool;
    POOL_ADDRESSES_PROVIDER = pool.ADDRESSES_PROVIDER();
  }

  function __ERC4626StataToken_init(address newAToken) internal onlyInitializing {
    IERC20 aTokenUnderlying = __ERC4626StataToken_init_unchained(newAToken);
    __ERC4626_init_unchained(aTokenUnderlying);
  }

  function __ERC4626StataToken_init_unchained(
    address newAToken
  ) internal onlyInitializing returns (IERC20) {
    // sanity check, to be sure that we support that version of the aToken
    address poolOfAToken = IAToken(newAToken).POOL();
    if (poolOfAToken != address(POOL)) revert PoolAddressMismatch(poolOfAToken);

    IERC20 aTokenUnderlying = IERC20(IAToken(newAToken).UNDERLYING_ASSET_ADDRESS());

    ERC4626StataTokenStorage storage $ = _getERC4626StataTokenStorage();
    $._aToken = IERC20(newAToken);

    SafeERC20.forceApprove(aTokenUnderlying, address(POOL), type(uint256).max);

    return aTokenUnderlying;
  }

  ///@inheritdoc IERC4626StataToken
  function depositATokens(uint256 assets, address receiver) external returns (uint256) {
    // because aToken is rebasable, we allow user to specify more then he has to compensate growth during the tx mining
    uint256 actualUserBalance = IERC20(aToken()).balanceOf(_msgSender());
    if (assets > actualUserBalance) {
      assets = actualUserBalance;
    }

    uint256 shares = previewDeposit(assets);
    _deposit(_msgSender(), receiver, assets, shares, false);

    return shares;
  }

  ///@inheritdoc IERC4626StataToken
  function depositWithPermit(
    uint256 assets,
    address receiver,
    uint256 deadline,
    SignatureParams memory sig,
    bool depositToAave
  ) external returns (uint256) {
    address assetToDeposit = depositToAave ? asset() : aToken();

    try
      IERC20Permit(assetToDeposit).permit(
        _msgSender(),
        address(this),
        assets,
        deadline,
        sig.v,
        sig.r,
        sig.s
      )
    {} catch {}

    // because aToken is rebasable, we allow user to specify more then he has to compensate growth during the tx mining
    // to make it consistent, we keep the same behaviour for the normal underlying too
    uint256 actualUserBalance = IERC20(assetToDeposit).balanceOf(_msgSender());
    if (assets > actualUserBalance) {
      assets = actualUserBalance;
    }

    uint256 shares = previewDeposit(assets);
    _deposit(_msgSender(), receiver, assets, shares, depositToAave);
    return shares;
  }

  ///@inheritdoc IERC4626StataToken
  function redeemATokens(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256) {
    uint256 assets = previewRedeem(shares);
    _withdraw(_msgSender(), receiver, owner, assets, shares, false);

    return assets;
  }

  ///@inheritdoc IERC4626StataToken
  function aToken() public view returns (address) {
    ERC4626StataTokenStorage storage $ = _getERC4626StataTokenStorage();
    return address($._aToken);
  }

  ///@inheritdoc IERC4626
  function maxMint(address) public view override returns (uint256) {
    uint256 assets = maxDeposit(address(0));
    if (assets == type(uint256).max) return type(uint256).max;
    return convertToShares(assets);
  }

  ///@inheritdoc IERC4626
  function maxWithdraw(address owner) public view override returns (uint256) {
    return convertToAssets(maxRedeem(owner));
  }

  ///@inheritdoc IERC4626
  function totalAssets() public view override returns (uint256) {
    return _convertToAssets(totalSupply(), Math.Rounding.Floor);
  }

  ///@inheritdoc IERC4626
  function maxRedeem(address owner) public view override returns (uint256) {
    DataTypes.ReserveConfigurationMap memory reserveConfiguration = POOL.getConfiguration(asset());

    // if paused or inactive users cannot withdraw underlying
    if (
      !ReserveConfiguration.getActive(reserveConfiguration) ||
      ReserveConfiguration.getPaused(reserveConfiguration)
    ) {
      return 0;
    }

    // otherwise users can withdraw up to the available amount
    uint128 virtualUnderlyingBalance = POOL.getVirtualUnderlyingBalance(asset());
    uint256 underlyingTokenBalanceInShares = convertToShares(virtualUnderlyingBalance);
    uint256 cachedUserBalance = balanceOf(owner);
    return
      underlyingTokenBalanceInShares >= cachedUserBalance
        ? cachedUserBalance
        : underlyingTokenBalanceInShares;
  }

  ///@inheritdoc IERC4626
  function maxDeposit(address) public view override returns (uint256) {
    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(asset());

    // if inactive, paused or frozen users cannot deposit underlying
    if (
      !ReserveConfiguration.getActive(reserveData.configuration) ||
      ReserveConfiguration.getPaused(reserveData.configuration) ||
      ReserveConfiguration.getFrozen(reserveData.configuration)
    ) {
      return 0;
    }

    uint256 supplyCap = ReserveConfiguration.getSupplyCap(reserveData.configuration) *
      (10 ** ReserveConfiguration.getDecimals(reserveData.configuration));
    // if no supply cap deposit is unlimited
    if (supplyCap == 0) return type(uint256).max;

    // return remaining supply cap margin
    uint256 currentSupply = (IAToken(reserveData.aTokenAddress).scaledTotalSupply() +
      reserveData.accruedToTreasury).mulDiv(_rate(), RAY, Math.Rounding.Ceil);
    return currentSupply >= supplyCap ? 0 : supplyCap - currentSupply;
  }

  ///@inheritdoc IERC4626StataToken
  function latestAnswer() external view returns (int256) {
    uint256 aTokenUnderlyingAssetPrice = IAaveOracle(POOL_ADDRESSES_PROVIDER.getPriceOracle())
      .getAssetPrice(asset());
    // @notice aTokenUnderlyingAssetPrice * rate / RAY
    return int256(aTokenUnderlyingAssetPrice.mulDiv(_rate(), RAY, Math.Rounding.Floor));
  }

  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares,
    bool depositToAave
  ) internal virtual {
    if (shares == 0) {
      revert StaticATokenInvalidZeroShares();
    }
    // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
    // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
    // calls the vault, which is assumed not malicious.
    //
    // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
    // assets are transferred and before the shares are minted, which is a valid state.
    // slither-disable-next-line reentrancy-no-eth

    if (depositToAave) {
      address cachedAsset = asset();
      SafeERC20.safeTransferFrom(IERC20(cachedAsset), caller, address(this), assets);
      POOL.deposit(cachedAsset, assets, address(this), 0);
    } else {
      ERC4626StataTokenStorage storage $ = _getERC4626StataTokenStorage();
      SafeERC20.safeTransferFrom($._aToken, caller, address(this), assets);
    }
    _mint(receiver, shares);

    emit Deposit(caller, receiver, assets, shares);
  }

  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _deposit(caller, receiver, assets, shares, true);
  }

  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares,
    bool withdrawFromAave
  ) internal virtual {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }

    // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
    // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
    // calls the vault, which is assumed not malicious.
    //
    // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
    // shares are burned and after the assets are transferred, which is a valid state.
    _burn(owner, shares);
    if (withdrawFromAave) {
      POOL.withdraw(asset(), assets, receiver);
    } else {
      ERC4626StataTokenStorage storage $ = _getERC4626StataTokenStorage();
      SafeERC20.safeTransfer($._aToken, receiver, assets);
    }

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    _withdraw(caller, receiver, owner, assets, shares, true);
  }

  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    // * @notice assets * RAY / exchangeRate
    return assets.mulDiv(RAY, _rate(), rounding);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    // * @notice share * exchangeRate / RAY
    return shares.mulDiv(_rate(), RAY, rounding);
  }

  function _rate() internal view returns (uint256) {
    return POOL.getReserveNormalizedIncome(asset());
  }
}

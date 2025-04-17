// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
import {EIP712} from 'openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol';
import {Nonces} from 'openzeppelin-contracts/contracts/utils/Nonces.sol';
import {IYieldMaestro} from './interfaces/IYieldMaestro.sol';

interface IERC1271 {
  function isValidSignature(bytes32, bytes memory) external view returns (bytes4);
}

contract sGHO is ERC4626, IERC20Permit, EIP712, Nonces {
  address public immutable gho;
  address public YIELD_MAESTRO;
  uint256 internal internalTotalAssets;
  uint256 internal lastupdate;

  // --- EIP712 niceties ---
  uint256 public immutable deploymentChainId;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
  string public constant VERSION = '1';

  /**
   * @dev Permit deadline has expired.
   */
  error ERC2612ExpiredSignature(uint256 deadline);

  /**
   * @dev Mismatched signature.
   */
  error ERC2612InvalidSigner(address signer, address owner);

  /**
   * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
   * @param _gho The address of the GHO token contract.
   * @param _yieldMaestro The address of the Yield Maestro contract.
   */
  constructor(
    address _gho,
    address _yieldMaestro
  ) ERC20('sGHO', 'sGHO') ERC4626(IERC20(_gho)) EIP712('sGHO', '1') {
    deploymentChainId = block.chainid;
    _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    gho = _gho;
    YIELD_MAESTRO = _yieldMaestro;
    internalTotalAssets = 0;
    lastupdate = block.timestamp;
  }

  receive() external payable {
    revert('No ETH allowed');
  }

  // --- Approve by signature ---

  function _isValidSignature(
    address signer,
    bytes32 digest,
    bytes memory signature
  ) internal view returns (bool) {
    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      if (signer == ecrecover(digest, v, r, s)) {
        return true;
      }
    }

    (bool success, bytes memory result) = signer.staticcall(
      abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, signature)
    );
    return (success &&
      result.length == 32 &&
      abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes memory signature
  ) public {
    require(block.timestamp <= deadline, 'SavingsXDai/permit-expired');
    require(owner != address(0), 'SavingsXDai/invalid-owner');

    uint256 nonce = _useNonce(owner);

    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        block.chainid == deploymentChainId
          ? _DOMAIN_SEPARATOR
          : _calculateDomainSeparator(block.chainid),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
      )
    );

    require(_isValidSignature(owner, digest, signature), 'SavingsXDai/invalid-permit');

    _approve(owner, spender, value);
    emit Approval(owner, spender, value);
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    permit(owner, spender, value, deadline, abi.encodePacked(r, s, v));
  }
  /**
   * @dev See {IERC20Permit-nonces}.
   */
  function nonces(
    address owner
  ) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
    return super.nonces(owner);
  }

  /**
   * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
   */
  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
    return _domainSeparatorV4();
  }

  function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
          ),
          keccak256(bytes(name())),
          keccak256(bytes(VERSION)),
          chainId,
          address(this)
        )
      );
  }

  // --- ERC4626 Logic ---

  function deposit(uint256 assets, address receiver) public override returns (uint256) {
    uint256 maxAssets = maxDeposit(receiver);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
    }

    uint256 shares = previewDeposit(assets);
    _updateVault(assets, true);
    _deposit(_msgSender(), receiver, assets, shares);

    return shares;
  }

  function mint(uint256 shares, address receiver) public override returns (uint256) {
    uint256 maxShares = maxMint(receiver);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
    }

    uint256 assets = previewMint(shares);
    _updateVault(assets, true);

    _deposit(_msgSender(), receiver, assets, shares);

    return assets;
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override returns (uint256) {
    uint256 maxAssets = maxWithdraw(owner);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
    }

    uint256 shares = previewWithdraw(assets);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    _updateVault(assets, false);

    return shares;
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override returns (uint256) {
    uint256 maxShares = maxRedeem(owner);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
    }

    uint256 assets = previewRedeem(shares);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    _updateVault(assets, false);

    return assets;
  }

  function totalAssets() public view override returns (uint256) {
    return internalTotalAssets;
  }

  /**
   * @dev Update the internal total assets of the vault.
   * This function is called when assets are deposited or withdrawn.
   * It also claims the savings from the Yield Maestro if the last update was more than 10 minutes ago.
   * @param assets The amount of assets to update.
   * @param assetIncrease A boolean indicating whether the assets are being increased or decreased.
   */
  function _updateVault(uint256 assets, bool assetIncrease) internal {
    uint256 currentTime = block.timestamp;
    uint256 claimed;

    if (currentTime > lastupdate + 600) {
      _claimSavings();
    }

    if (assetIncrease) {
      internalTotalAssets += assets;
    } else {
      internalTotalAssets -= assets;
    }
  }

  function _claimSavings() internal {
    uint256 claimed = IYieldMaestro(YIELD_MAESTRO).claimSavings();
    internalTotalAssets += claimed;
    lastupdate = block.timestamp;
  }

  /**
   * @dev Transfer any excess GHO tokens to the Yield Maestro.
   */
  function takeDonated() external {
    uint256 balance = IERC20(gho).balanceOf(address(this));
    if (balance > internalTotalAssets) {
      IERC20(gho).transfer(YIELD_MAESTRO, balance - internalTotalAssets);
    }
  }
}

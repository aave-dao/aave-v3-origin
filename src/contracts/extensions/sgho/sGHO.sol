// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {ERC4626, ERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol';
import {ERC20Permit, EIP712} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {WadRayMath} from '../../../contracts/protocol/libraries/math/WadRayMath.sol';
import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import {IsGHO} from './interfaces/IsGHO.sol';

interface IERC1271 {
  function isValidSignature(bytes32, bytes memory) external view returns (bytes4);
}

contract sGHO is ERC4626, ERC20Permit, Initializable, IsGHO {
  using WadRayMath for uint256;
  using Math for uint256;

  address public immutable gho;
  IAccessControl internal aclManager;

  uint256 public targetRate;
  uint256 public internalTotalAssets;
  uint256 public yieldIndex;
  uint256 public lastUpdate;
  uint256 internal ratePerSecond;
  uint256 internal indexChangePerSecond;
  uint256 internal constant RATE_PRECISION = 1e10;
  uint256 internal constant ONE_YEAR = 365 days;

  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';
  bytes32 public constant YIELD_MANAGER_ROLE = 'YIELD_MANAGER';

  // --- EIP712 niceties ---
  uint256 public deploymentChainId;
  bytes32 private _DOMAIN_SEPARATOR;
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
  string public constant VERSION = '1';

  /**
   * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
   * @param _gho The address of the GHO token contract.
   */
  constructor(
    address _gho,
    address _aclmanager
  ) ERC20('sGHO', 'sGHO') ERC4626(IERC20(_gho)) ERC20Permit('sGHO') {
    gho = _gho;
    aclManager = IAccessControl(_aclmanager);
  }

  receive() external payable {
    revert NoEthAllowed();
  }

  /**
   * @dev Throws if the contract is not initialized.
   */
  modifier isInitialized() {
    if (_getInitializedVersion() == 0) {
      revert NotInitialized();
    }
    _;
  }

  /**
   * @dev Throws if the caller does not have the YIELD_MANAGER role
   */
  modifier onlyYieldManager() {
    if (_onlyYieldManager() == false) {
      revert OnlyYieldManager();
    }
    _;
  }

  /**
   * @dev Throws if the caller does not have the FUNDS_ADMIN role
   */
  modifier onlyFundsAdmin() {
    if (_onlyFundsAdmin() == false) {
      revert OnlyFundsAdmin();
    }
    _;
  }

  /**
   * @dev Initialize receiver, require minimum balance to not set a dripRate of 0
   */
  function initialize() public payable initializer {
    deploymentChainId = block.chainid;
    _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    yieldIndex = WadRayMath.RAY;
    lastUpdate = block.timestamp;
    internalTotalAssets = 0;
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
    if (block.timestamp > deadline) {
      revert ERC2612ExpiredSignature(deadline);
    }

    if (owner == address(0)) {
      revert ERC2612InvalidSigner(owner, spender);
    }

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

    if (!_isValidSignature(owner, digest, signature)) {
      revert InvalidSignature();
    }

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
  ) public virtual override(IsGHO, ERC20Permit) {
    permit(owner, spender, value, deadline, abi.encodePacked(r, s, v));
  }
  /**
   * @dev See {IERC20Permit-nonces}.
   */
  function nonces(address owner) public view virtual override(ERC20Permit) returns (uint256) {
    return super.nonces(owner);
  }

  /**
   * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
   */
  function DOMAIN_SEPARATOR() external view virtual override returns (bytes32) {
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

  function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
    return super.decimals();
  }

  // --- ERC4626 Logic ---

  function deposit(uint256 assets, address receiver) public override(ERC4626) returns (uint256) {
    uint256 maxAssets = maxDeposit(receiver);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
    }

    uint256 shares = previewDeposit(assets);
    _updateVaultState(assets, true);
    _deposit(_msgSender(), receiver, assets, shares);

    return shares;
  }

  function mint(uint256 shares, address receiver) public override(ERC4626) returns (uint256) {
    uint256 maxShares = maxMint(receiver);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
    }

    uint256 assets = previewMint(shares);
    _updateVaultState(assets, true);

    _deposit(_msgSender(), receiver, assets, shares);

    return assets;
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override(ERC4626) returns (uint256) {
    uint256 maxAssets = maxWithdraw(owner);
    if (assets > maxAssets) {
      revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
    }

    uint256 shares = previewWithdraw(assets);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    _updateVaultState(assets, false);

    return shares;
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override(ERC4626) returns (uint256) {
    uint256 maxShares = maxRedeem(owner);
    if (shares > maxShares) {
      revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
    }

    uint256 assets = previewRedeem(shares);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    _updateVaultState(assets, false);

    return assets;
  }

  function totalAssets() public view override(ERC4626) returns (uint256) {
    return internalTotalAssets;
  }

  /**
   * @dev Override the conversion functions to use the yield index
   */
  function _convertToShares(
    uint256 assets,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    uint256 currentYieldIndex = _getCurrentYieldIndex();
    if (currentYieldIndex == 0) return 0;
    return Math.mulDiv(assets, WadRayMath.RAY, currentYieldIndex, rounding);
  }

  function _convertToAssets(
    uint256 shares,
    Math.Rounding rounding
  ) internal view virtual override returns (uint256) {
    uint256 currentYieldIndex = _getCurrentYieldIndex();
    return Math.mulDiv(shares, currentYieldIndex, WadRayMath.RAY, rounding);
  }

  /**
   * @dev Get the current yield index including accrued interest
   */
  function _getCurrentYieldIndex() internal view returns (uint256) {
    if (targetRate == 0) return yieldIndex;

    uint256 timeSinceLastUpdate = block.timestamp - lastUpdate;
    if (timeSinceLastUpdate == 0) return yieldIndex;

    // Calculate the rate per second based on the target rate
    uint256 currentRatePerSecond = targetRate.wadDiv(ONE_YEAR);

    // Calculate the index change per second
    uint256 currentIndexChangePerSecond = yieldIndex.rayMul(currentRatePerSecond).rayDiv(
      WadRayMath.RAY
    );

    // Calculate the total index change over the time period
    uint256 totalIndexChange = currentIndexChangePerSecond.rayMul(timeSinceLastUpdate);

    return yieldIndex + totalIndexChange;
  }

  /**
   * @dev Update the vault state when assets are deposited or withdrawn.
   * This function updates both the yield index and internal total assets.
   * @param assets The amount of assets being deposited or withdrawn.
   * @param assetIncrease A boolean indicating whether the assets are being increased or decreased.
   */
  function _updateVaultState(uint256 assets, bool assetIncrease) internal {
    // First, update the yield index to accrue interest up to current time
    uint256 yieldIndexChange = _updateYieldIndex();
  
    // Then update the internal total assets
    if (assetIncrease) {
      internalTotalAssets += assets + yieldIndexChange;
    } else {
      internalTotalAssets = internalTotalAssets - assets + yieldIndexChange;
    }
  }

  /**
   * @dev Update the yield index to accrue interest up to the current timestamp
   */
  function _updateYieldIndex() internal returns (uint256 yieldIndexChange) {
    if (targetRate == 0) return 0;

    uint256 timeSinceLastUpdate = block.timestamp - lastUpdate;
    if (timeSinceLastUpdate == 0) return 0;

    // Calculate the rate per second based on the target rate
    ratePerSecond = targetRate.wadDiv(ONE_YEAR);

    // Calculate the index change per second
    indexChangePerSecond = yieldIndex.rayMul(ratePerSecond).rayDiv(WadRayMath.RAY);

    yieldIndexChange = indexChangePerSecond.rayMul(timeSinceLastUpdate);
    // Update the yield index
    yieldIndex += yieldIndexChange;

    // Update the last update timestamp
    lastUpdate = block.timestamp;
  }

  /**
   * @dev Informs about approximate sGHO vault APR based on target rate
   * @return amount of interest collected per year divided by amount of current deposits in vault
   */
  function vaultAPR() external view returns (uint256) {
    return targetRate.wadDiv(WadRayMath.RAY);
  }

  /**
   * @dev set new target rate in APR, such that a target rate of 10% should have input 1000
   * @param newRate New APR to be set (in basis points, e.g., 1000 = 10%)
   */
  function setTargetRate(uint256 newRate) public onlyYieldManager {
    // Update the yield index before changing the rate to ensure proper accrual
    _updateYieldIndex();
    targetRate = newRate.wadMul(WadRayMath.RAY);
  }

  function rescueERC20(address erc20Token, address to, uint256 amount) external onlyFundsAdmin {
    if (erc20Token == gho) {
      revert CannotRescueGHO();
    }
    uint256 max = IERC20(erc20Token).balanceOf(address(this));
    amount = max > amount ? amount : max;
    IERC20(erc20Token).transfer(to, amount);
    emit ERC20Rescued(msg.sender, erc20Token, to, amount);
  }

  function _onlyFundsAdmin() internal view returns (bool) {
    return aclManager.hasRole(FUNDS_ADMIN_ROLE, msg.sender);
  }

  function _onlyYieldManager() internal view returns (bool) {
    return aclManager.hasRole(YIELD_MANAGER_ROLE, msg.sender);
  }
}

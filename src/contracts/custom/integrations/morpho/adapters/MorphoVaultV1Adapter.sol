// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {ReentrancyGuard} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';
import {IVaultV2Adapter} from '../interfaces/IVaultV2Adapter.sol';

interface IMorphoVaultV1 {
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
  function convertToAssets(uint256 shares) external view returns (uint256);
  function convertToShares(uint256 assets) external view returns (uint256);
  function maxWithdraw(address owner) external view returns (uint256);
  function asset() external view returns (address);
}

/**
 * @title MorphoVaultV1Adapter
 * @notice Morpho Vault V2 adapter for liquid Morpho V1 vaults
 */
contract MorphoVaultV1Adapter is IVaultV2Adapter, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address public immutable override vault;
  address public immutable override asset;
  IMorphoVaultV1 public immutable morphoV1Vault;
  uint256 public sharesHeld;

  bytes32 public constant RISK_ID_ADAPTER = keccak256('adapter:v1-liquidity');

  error OnlyVault();
  error InsufficientAssets();
  error ZeroAddress();

  modifier onlyVault() {
    if (msg.sender != vault) revert OnlyVault();
    _;
  }

  constructor(address _vault, address _morphoV1Vault) Ownable(msg.sender) {
    if (_vault == address(0) || _morphoV1Vault == address(0)) revert ZeroAddress();
    vault = _vault;
    morphoV1Vault = IMorphoVaultV1(_morphoV1Vault);
    asset = morphoV1Vault.asset();
    IERC20(asset).approve(_morphoV1Vault, type(uint256).max);
  }

  function allocate(bytes memory data, uint256 assets, bytes4, address) external override onlyVault nonReentrant returns (bytes32[] memory _ids, int256 delta) {
    IERC20(asset).safeTransferFrom(vault, address(this), assets);
    uint256 shares = morphoV1Vault.deposit(assets, address(this));
    sharesHeld += shares;
    _ids = ids();
    delta = int256(assets);
    emit Allocated(assets, data);
  }

  function deallocate(bytes memory data, uint256 assets, bytes4, address) external override onlyVault nonReentrant returns (bytes32[] memory _ids, int256 delta) {
    if (assets > realAssets()) revert InsufficientAssets();
    uint256 sharesToBurn = morphoV1Vault.convertToShares(assets);
    uint256 withdrawn = morphoV1Vault.redeem(sharesToBurn, address(this), address(this));
    sharesHeld = sharesHeld > sharesToBurn ? sharesHeld - sharesToBurn : 0;
    IERC20(asset).safeTransfer(vault, withdrawn);
    _ids = ids();
    delta = -int256(withdrawn);
    emit Deallocated(withdrawn, data);
  }

  function realAssets() public view override returns (uint256) {
    if (sharesHeld == 0) return 0;
    return morphoV1Vault.convertToAssets(sharesHeld);
  }

  function ids() public pure override returns (bytes32[] memory) {
    bytes32[] memory _ids = new bytes32[](1);
    _ids[0] = RISK_ID_ADAPTER;
    return _ids;
  }

  function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(owner(), amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ReentrancyGuard} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';

/**
 * @title JpyUbiAMOMinter
 * @notice AMO (Algorithmic Market Operations) Minter for JpyUbi stablecoin
 * @dev Manages minting and burning operations for algorithmic market operations
 */
contract JpyUbiAMOMinter is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address public jpyUbiToken;
  mapping(address => bool) public isAMO;
  mapping(address => uint256) public amoMintedBalance;
  uint256 public totalAMOMinted;
  uint256 public globalMintCap;

  event AMOAdded(address indexed amo);
  event AMORemoved(address indexed amo);
  event AMOMinted(address indexed amo, uint256 amount);
  event AMOBurned(address indexed amo, uint256 amount);
  event GlobalMintCapUpdated(uint256 newCap);

  error NotAMO();
  error ZeroAddress();
  error ExceedsMintCap();
  error ExceedsBurnAmount();

  modifier onlyAMO() {
    if (!isAMO[msg.sender]) revert NotAMO();
    _;
  }

  constructor(address _jpyUbiToken, uint256 _globalMintCap) Ownable(msg.sender) {
    if (_jpyUbiToken == address(0)) revert ZeroAddress();
    jpyUbiToken = _jpyUbiToken;
    globalMintCap = _globalMintCap;
  }

  function addAMO(address _amo) external onlyOwner {
    if (_amo == address(0)) revert ZeroAddress();
    isAMO[_amo] = true;
    emit AMOAdded(_amo);
  }

  function removeAMO(address _amo) external onlyOwner {
    isAMO[_amo] = false;
    emit AMORemoved(_amo);
  }

  function mintToAMO(uint256 _amount) external onlyAMO nonReentrant {
    if (totalAMOMinted + _amount > globalMintCap) revert ExceedsMintCap();
    amoMintedBalance[msg.sender] += _amount;
    totalAMOMinted += _amount;
    // Note: Actual minting would call jpyUbiToken.mint(msg.sender, _amount)
    // This requires the minter to have facilitator rights on the token
    emit AMOMinted(msg.sender, _amount);
  }

  function burnFromAMO(uint256 _amount) external onlyAMO nonReentrant {
    if (_amount > amoMintedBalance[msg.sender]) revert ExceedsBurnAmount();
    amoMintedBalance[msg.sender] -= _amount;
    totalAMOMinted -= _amount;
    // Note: Actual burning would call jpyUbiToken.burn(_amount)
    emit AMOBurned(msg.sender, _amount);
  }

  function setGlobalMintCap(uint256 _newCap) external onlyOwner {
    globalMintCap = _newCap;
    emit GlobalMintCapUpdated(_newCap);
  }

  function getAMOMintedBalance(address _amo) external view returns (uint256) {
    return amoMintedBalance[_amo];
  }

  function availableMintCapacity() external view returns (uint256) {
    return globalMintCap > totalAMOMinted ? globalMintCap - totalAMOMinted : 0;
  }
}

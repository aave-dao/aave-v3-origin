// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {AccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';
import {IYieldMaestro} from './interfaces/IYieldMaestro.sol';

contract YieldMaestro is Initializable, AccessControl, IYieldMaestro {
  IERC20 public immutable gho;
  address public immutable sGHO;
  IACLManager internal aclManager;

  uint256 public lastClaimTimestamp;
  uint256 public targetRate;

  uint256 internal constant RATE_PRECISION = 1e8;
  uint256 internal constant ONE_YEAR = 365 days;

  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';
  bytes32 public constant YIELD_MANAGER_ROLE = 'YIELD_MANAGER';

  constructor(address _gho, address _sGho, address _aclmanager) {
    gho = IERC20(_gho);
    sGHO = _sGho;
    aclManager = IACLManager(_aclmanager);
  }

  modifier isInitialized() {
    require(_getInitializedVersion() > 0, 'Not Initialized');
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
    lastClaimTimestamp = block.timestamp;
    setTargetRate(0);
  }

  function claimSavings() public isInitialized returns (uint256 claimed) {
    // if targetRate is 0 skip it
    if (targetRate > 0) {
      uint256 unclaimed = _calculateUnclaimed();
      gho.transfer(sGHO, unclaimed);
      claimed = unclaimed;
      emit Claimed(claimed);
    }
    lastClaimTimestamp = block.timestamp;
  }

  function _calculateUnclaimed() public view returns (uint256) {
    // Calculate the time elapsed since the last claim
    uint256 elapsedTime = block.timestamp - lastClaimTimestamp;
    uint256 vaultAssets = IERC4626(sGHO).totalAssets();

    // Calculate unclaimed rewards based on targetRate
    uint256 unclaimedRewards = (vaultAssets * targetRate * elapsedTime) /
      (RATE_PRECISION * ONE_YEAR);
    return unclaimedRewards;
  }

  /**
   * @dev Preview how much would be claimable
   */
  function previewClaimable() external view returns (uint256 claimable) {
    claimable = _calculateUnclaimed();
  }

  /**
   * @dev Informs about approximate sDAI vault APR based on incoming bridged interest and vault deposits
   * @return amount of interest collected per year divided by amount of current deposits in vault
   */
  function vaultAPR() external view returns (uint256) {
    return targetRate / 1e6;
  }

  /**
   * @dev set new target rate in APR, such that a target rate of 10% should have input 1000
   * @param newRate New APR to be set
   */
  function setTargetRate(uint256 newRate) public onlyYieldManager {
    // offset by 2 decimals relative to RATE_PRECISION
    targetRate = newRate * 1e6;
  }

  function rescueERC20(address erc20Token, address to, uint256 amount) external onlyFundsAdmin {
    uint256 max = IERC20(erc20Token).balanceOf(address(this));
    amount = max > amount ? amount : max;
    IERC20(erc20Token).transfer(to, amount);
    emit ERC20Rescued(msg.sender, erc20Token, to, amount);
  }

  receive() external payable {
    revert('No ETH allowed');
  }

  function _onlyFundsAdmin() internal view returns (bool) {
    return hasRole(FUNDS_ADMIN_ROLE, msg.sender);
  }

  function _onlyYieldManager() internal view returns (bool) {
    return hasRole(YIELD_MANAGER_ROLE, msg.sender);
  }
}

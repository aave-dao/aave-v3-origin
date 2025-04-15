// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {Initializable} from 'openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {sGHO} from './sGHO.sol';

contract YieldMaestro is Initializable {
  IERC20 public constant gho;
  address public constant sGHO;

  uint256 public lastClaimTimestamp;
  uint256 public targetRate;

  uint256 internal constant RATE_PRECISION = 1e8;
  uint256 internal constant ONE_YEAR = 365 days;

  event Claimed(uint256 indexed amount);

  constructor(address _sGho, address aclm) {
    sGHO = _sGho;
    claimer = msg.sender;
  }

  modifier isInitialized() {
    require(_getInitializedVersion() > 0, 'Not Initialized');
    _;
  }

  modifier onlyYieldManagerOrAdmin() {
    if( msg.sender != aclManager.isYieldManager() && msg.sender != aclManager.isPoolAdmin(), 'Not Yield Manager'){
        revert onlyAdmin();
    }
    _;
  }

  modifier onlyAdmin() {
    if (msg.sender != aclManager.isPoolAdmin()) {
      revert onlyAdmin();
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
    // if APY is 0 skip it
    if (apy > 0) {
      (unclaimed) = _calculateUnclaimed();
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

    // Calculate unclaimed rewards based on APY
    uint256 unclaimedRewards = (vaultAssets * targetRate * elapsedTime) / (RATE_PRECISION * ONE_YEAR);
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
   * @param newRate 
   * @return amount of interest collected per year divided by amount of current deposits in vault
   */
  function setTargetRate(uint256 newRate) external onlyYieldManagerOrAdmin {
    // offset by 2 decimals relative to RATE_PRECISION
    targetRate = newRate * 1e6
  }

  /// @inheritdoc IRescuableBase
  function rescueERC20(address erc20Token, address to, uint256 amount) external onlyAdmin() {
    uint256 max = IERC20(erc20Token).balanceOf(address(this));
    amount = max > amount ? amount : max;
    IERC20(erc20Token).safeTransfer(to, amount);
    emit ERC20Rescued(msg.sender, erc20Token, to, amount);
  }

  receive() external payable {
    revert('No ETH allowed');
  }
}

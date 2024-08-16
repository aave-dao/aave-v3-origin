// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC20Upgradeable, ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {PausableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';
import {IRescuable, Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {IACLManager} from '../../../core/contracts/interfaces/IACLManager.sol';
import {ERC4626Upgradeable, ERC4626StataTokenUpgradeable, IPool} from './ERC4626StataTokenUpgradeable.sol';
import {ERC20AaveLMUpgradeable, IRewardsController} from './ERC20AaveLMUpgradeable.sol';
import {IStataTokenV2} from './interfaces/IStataTokenV2.sol';

contract StataTokenV2 is
  ERC20PermitUpgradeable,
  ERC20AaveLMUpgradeable,
  ERC4626StataTokenUpgradeable,
  PausableUpgradeable,
  Rescuable,
  IStataTokenV2
{
  constructor(
    IPool pool,
    IRewardsController rewardsController
  ) ERC20AaveLMUpgradeable(rewardsController) ERC4626StataTokenUpgradeable(pool) {
    _disableInitializers();
  }

  modifier onlyPauseGuardian() {
    if (!canPause(_msgSender())) revert OnlyPauseGuardian(_msgSender());
    _;
  }

  function initialize(
    address aToken,
    string calldata staticATokenName,
    string calldata staticATokenSymbol
  ) external initializer {
    __ERC20_init(staticATokenName, staticATokenSymbol);
    __ERC20Permit_init(staticATokenName);
    __ERC20AaveLM_init(aToken);
    __ERC4626StataToken_init(aToken);
    __Pausable_init();
  }

  ///@inheritdoc IStataTokenV2
  function setPaused(bool paused) external onlyPauseGuardian {
    if (paused) _pause();
    else _unpause();
  }

  /// @inheritdoc IRescuable
  function whoCanRescue() public view override returns (address) {
    return POOL_ADDRESSES_PROVIDER.getACLAdmin();
  }

  ///@inheritdoc IStataTokenV2
  function canPause(address actor) public view returns (bool) {
    return IACLManager(POOL_ADDRESSES_PROVIDER.getACLManager()).isEmergencyAdmin(actor);
  }

  function decimals() public view override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
    /// @notice The initialization of ERC4626Upgradeable already assures that decimal are
    /// the same as the underlying asset of the StataTokenV2, e.g. decimals of WETH for stataWETH
    return ERC4626Upgradeable.decimals();
  }

  function _claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) internal virtual override whenNotPaused {
    super._claimRewardsOnBehalf(onBehalfOf, receiver, rewards);
  }

  // @notice to merge inheritance with ERC20AaveLMUpgradeable.sol properly we put
  // `whenNotPaused` here instead of using ERC20PausableUpgradeable
  function _update(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20AaveLMUpgradeable, ERC20Upgradeable) whenNotPaused {
    ERC20AaveLMUpgradeable._update(from, to, amount);
  }
}

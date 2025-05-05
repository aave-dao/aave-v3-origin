// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {RWAAToken} from 'src/contracts/protocol/tokenization/RWAAToken.sol';
import {IPool, IAaveIncentivesController, IInitializableAToken, Errors, VersionedInitializable} from 'src/contracts/protocol/tokenization/AToken.sol';

contract RWAATokenInstance is RWAAToken {
  uint256 public constant RWA_ATOKEN_REVISION = 1;

  constructor(IPool pool) RWAAToken(pool, 'RWA_ATOKEN_IMPL', 'RWA_ATOKEN_IMPL') {}

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return RWA_ATOKEN_REVISION;
  }

  /// @inheritdoc IInitializableAToken
  function initialize(
    IPool initializingPool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) public virtual override initializer {
    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
    _setName(aTokenName);
    _setSymbol(aTokenSymbol);
    _setDecimals(aTokenDecimals);

    _treasury = treasury;
    _underlyingAsset = underlyingAsset;
    _incentivesController = incentivesController;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      treasury,
      address(incentivesController),
      aTokenDecimals,
      aTokenName,
      aTokenSymbol,
      params
    );
  }
}

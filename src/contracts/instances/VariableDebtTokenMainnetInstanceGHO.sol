// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VersionedInitializable} from '../misc/aave-upgradeability/VersionedInitializable.sol';
import {VariableDebtToken, IPool, IInitializableDebtToken, Errors} from '../protocol/tokenization/VariableDebtToken.sol';

/**
 * @title Aave ERC20 VariableDebtToken Instance for GHO token in Mainnet
 * @author BGD Labs
 * @notice Instance of the variable debt token for the Aave protocol for GHO token in Mainnet
 */
contract VariableDebtTokenMainnetInstanceGHO is VariableDebtToken {
  uint256 public constant DEBT_TOKEN_REVISION = 5;

  constructor(IPool pool, address rewardsController) VariableDebtToken(pool, rewardsController) {}

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return DEBT_TOKEN_REVISION;
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IPool initializingPool,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external override initializer {
    require(initializingPool == POOL, Errors.PoolAddressesDoNotMatch());
    _setName(debtTokenName);
    _setSymbol(debtTokenSymbol);
    _setDecimals(debtTokenDecimals);

    _underlyingAsset = underlyingAsset;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      address(REWARDS_CONTROLLER),
      debtTokenDecimals,
      debtTokenName,
      debtTokenSymbol,
      params
    );
  }

  // @note deprecated discount hook being called by stkAAVE, not used since v3.4
  function updateDiscountDistribution(address, address, uint256, uint256, uint256) external {}
}

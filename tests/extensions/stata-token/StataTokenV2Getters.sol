// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {IERC20Metadata, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {AToken} from '../../../src/contracts/protocol/tokenization/AToken.sol';
import {StataTokenV2} from '../../../src/contracts/extensions/stata-token/StataTokenV2.sol'; // TODO: change import to isolate to 4626
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2GettersTest is BaseTest {
  function test_initializeShouldRevert() public {
    address impl = factory.STATA_TOKEN_IMPL();
    vm.expectRevert(Initializable.InvalidInitialization.selector);
    StataTokenV2(impl).initialize(aToken, 'hey', 'ho');
  }

  function test_getters() public view {
    assertEq(stataTokenV2.name(), 'Wrapped Aave Local WETH');
    assertEq(stataTokenV2.symbol(), 'waLocWETH');

    address referenceAsset = stataTokenV2.getReferenceAsset();
    assertEq(referenceAsset, aToken);

    address underlyingAddress = address(stataTokenV2.asset());
    assertEq(underlyingAddress, underlying);

    assertEq(stataTokenV2.aToken(), contracts.poolProxy.getReserveAToken(underlyingAddress));

    IERC20Metadata underlying = IERC20Metadata(underlyingAddress);
    assertEq(stataTokenV2.decimals(), underlying.decimals());

    assertEq(
      address(stataTokenV2.INCENTIVES_CONTROLLER()),
      address(AToken(aToken).getIncentivesController())
    );
  }
}

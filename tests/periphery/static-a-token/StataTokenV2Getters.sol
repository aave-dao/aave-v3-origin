// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {IERC20Metadata, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {AToken} from '../../../src/core/contracts/protocol/tokenization/AToken.sol';
import {StataTokenV2} from '../../../src/periphery/contracts/static-a-token/StataTokenV2.sol'; // TODO: change import to isolate to 4626
import {BaseTest} from './TestBase.sol';

contract StataTokenV2GettersTest is BaseTest {
  function test_initializeShouldRevert() public {
    address impl = factory.STATIC_A_TOKEN_IMPL();
    vm.expectRevert(Initializable.InvalidInitialization.selector);
    StataTokenV2(impl).initialize(aToken, 'hey', 'ho');
  }

  function test_getters() public view {
    assertEq(stataTokenV2.name(), 'Static Aave Local WETH v2');
    assertEq(stataTokenV2.symbol(), 'stataLocWETHv2');

    address referenceAsset = stataTokenV2.getReferenceAsset();
    assertEq(referenceAsset, aToken);

    address underlyingAddress = address(stataTokenV2.asset());
    assertEq(underlyingAddress, underlying);

    IERC20Metadata underlying = IERC20Metadata(underlyingAddress);
    assertEq(stataTokenV2.decimals(), underlying.decimals());

    assertEq(
      address(stataTokenV2.INCENTIVES_CONTROLLER()),
      address(AToken(aToken).getIncentivesController())
    );
  }
}

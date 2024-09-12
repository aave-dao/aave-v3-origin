// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IAToken} from '../../../src/contracts/extensions/static-a-token/StataTokenV2.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2RescuableTest is BaseTest {
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  function test_rescuable_shouldTransferAssetsToCollector() external {
    deal(tokenList.usdx, address(stataTokenV2), 1 ether);
    stataTokenV2.emergencyTokenTransfer(tokenList.usdx, 1 ether);
  }

  function test_rescuable_shouldWorkForAToken() external {
    _fundAToken(1 ether, address(stataTokenV2));
    stataTokenV2.emergencyTokenTransfer(aToken, 1 ether);
  }

  function test_rescuable_shouldNotCauseInsolvency(uint256 donation, uint256 stake) external {
    vm.assume(donation != 0 && donation <= type(uint96).max);
    vm.assume(stake != 0 && stake <= type(uint96).max);
    _fundAToken(donation, address(stataTokenV2));
    _fund4626(stake, address(this));

    address treasury = IAToken(aToken).RESERVE_TREASURY_ADDRESS();

    vm.expectEmit(true, true, true, true);
    emit ERC20Rescued(address(this), aToken, treasury, donation);
    stataTokenV2.emergencyTokenTransfer(aToken, donation + stake);
  }
}

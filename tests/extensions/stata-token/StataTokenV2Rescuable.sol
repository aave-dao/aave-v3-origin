// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {IAToken} from '../../../src/contracts/extensions/stata-token/StataTokenV2.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2RescuableTest is BaseTest {
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  function test_rescuable_shouldRevertForInvalidCaller() external {
    deal(tokenList.usdx, address(stataTokenV2), 1 ether);
    vm.expectRevert(abi.encodeWithSelector(IRescuable.OnlyRescueGuardian.selector));
    IRescuable(address(stataTokenV2)).emergencyTokenTransfer(
      tokenList.usdx,
      address(this),
      1 ether
    );
  }

  function test_rescuable_shouldTransferAssetsToCollector() external {
    deal(tokenList.usdx, address(stataTokenV2), 1 ether);
    vm.startPrank(poolAdmin);
    stataTokenV2.emergencyTokenTransfer(tokenList.usdx, address(this), 1 ether);
    assertEq(IERC20(tokenList.usdx).balanceOf(address(this)), 1 ether);
  }

  function test_rescuable_shouldWorkForAToken() external {
    _fundAToken(1 ether, address(stataTokenV2));
    vm.startPrank(poolAdmin);
    stataTokenV2.emergencyTokenTransfer(aToken, address(this), 1 ether);
    assertApproxEqAbs(IERC20(aToken).balanceOf(address(this)), 1 ether, 1);
  }

  function test_rescuable_shouldNotCauseInsolvency(uint256 donation, uint256 stake) external {
    vm.assume(donation != 0 && donation <= type(uint96).max);
    vm.assume(stake != 0 && stake <= type(uint96).max);
    _fundAToken(donation, address(stataTokenV2));
    _fund4626(stake, address(this));

    vm.expectEmit(true, true, true, true);
    emit ERC20Rescued(poolAdmin, aToken, address(this), donation);
    vm.startPrank(poolAdmin);
    stataTokenV2.emergencyTokenTransfer(aToken, address(this), donation + stake);
  }
}

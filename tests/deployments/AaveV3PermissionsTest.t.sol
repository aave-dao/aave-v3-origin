// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from '../../src/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IPoolAddressesProvider} from '../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import '../../src/deployments/interfaces/IMarketReportTypes.sol';
import {ACLManager} from '../../src/contracts/protocol/configuration/ACLManager.sol';
import {RewardsController} from '../../src/contracts/rewards/RewardsController.sol';
import {EmissionManager} from '../../src/contracts/rewards/EmissionManager.sol';
import {AugustusRegistryMock} from '../mocks/AugustusRegistryMock.sol';
import {WETH9} from '../../src/contracts/dependencies/weth/WETH9.sol';
import {BatchTestProcedures} from '../utils/BatchTestProcedures.sol';
import {IRevenueSplitter} from '../../src/contracts/treasury/IRevenueSplitter.sol';

contract AaveV3PermissionsTest is BatchTestProcedures {
  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  function testCheckPermissions() public {
    bytes32 emptyBytes;
    address marketOwner = makeAddr('MARKET_OWNER');
    address emergencyAdmin = makeAddr('EMERGENCY_ADMIN');
    address poolAdmin = makeAddr('POOL_ADMIN');
    address deployer = msg.sender;
    (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    ) = _getMarketInput(marketOwner);

    roles.emergencyAdmin = emergencyAdmin;
    roles.poolAdmin = poolAdmin;

    config.paraswapAugustusRegistry = address(new AugustusRegistryMock());
    config.wrappedNativeToken = address(new WETH9());

    MarketReport memory report = deployAaveV3Testnet(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    ACLManager aclManager = ACLManager(
      IPoolAddressesProvider(report.poolAddressesProvider).getACLManager()
    );
    {
      address providerOwner = Ownable(report.poolAddressesProvider).owner();
      assertEq(
        providerOwner,
        roles.marketOwner,
        'PoolAddressesProvider owner must be roles.marketOwner'
      );
    }
    {
      address providerRegistryOwner = Ownable(report.poolAddressesProviderRegistry).owner();
      assertEq(
        providerRegistryOwner,
        roles.marketOwner,
        'PoolAddressesProviderRegistry owner must be roles.marketOwner'
      );
    }
    {
      address providerAclAdmin = IPoolAddressesProvider(report.poolAddressesProvider).getACLAdmin();
      assertEq(
        providerAclAdmin,
        roles.poolAdmin,
        'PoolAddressesProvider.getACLAdmin() must be pool admin'
      );
    }
    {
      bool isPoolAdminDefaultAdmin = aclManager.hasRole(emptyBytes, roles.poolAdmin);
      assertTrue(isPoolAdminDefaultAdmin, 'roles.PoolAdmin must be default admin');
    }
    {
      bool isPoolAdminCorrect = aclManager.isPoolAdmin(roles.poolAdmin);
      assertTrue(isPoolAdminCorrect, 'roles.PoolAdmin must be pool admin');
    }
    {
      bool isEmergencyAdminCorrect = aclManager.isEmergencyAdmin(roles.emergencyAdmin);
      assertTrue(isEmergencyAdminCorrect, 'roles.emergencyAdmin must be emergency admin');
    }
    {
      bool isDeployerDefaultAdmin = aclManager.hasRole(emptyBytes, deployer);
      assertFalse(isDeployerDefaultAdmin, 'Deployer should not be default admin');
    }
    {
      bool isDeployerPoolAdmin = aclManager.isPoolAdmin(deployer);
      assertFalse(isDeployerPoolAdmin, 'deployer should not be pool admin');
    }
    {
      bool isDeployerEmergencyAdmin = aclManager.isEmergencyAdmin(deployer);
      assertFalse(isDeployerEmergencyAdmin, 'Deployer should not be emergency admin');
    }
    {
      bool isDeployerAssetListAdmin = aclManager.isAssetListingAdmin(deployer);
      assertFalse(isDeployerAssetListAdmin, 'Deployer should not be listing admin');
    }
    {
      address paraswapSwapAdapterOwner = Ownable(report.paraSwapLiquiditySwapAdapter).owner();
      address paraswapRepayAdapterOwner = Ownable(report.paraSwapRepayAdapter).owner();
      address paraswapWithdrawSwapOwner = Ownable(report.paraSwapWithdrawSwapAdapter).owner();
      assertEq(
        paraswapRepayAdapterOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap repay owner'
      );
      assertEq(
        paraswapSwapAdapterOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap liquidity swap owner'
      );
      assertEq(
        paraswapWithdrawSwapOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap withdraw swap owner'
      );
    }
    {
      address wethGatewayOwner = Ownable(report.wrappedTokenGateway).owner();
      assertEq(
        wethGatewayOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be WrappedTokenGateway owner'
      );
    }
    {
      address rewardsControllerAdmin = RewardsController(report.rewardsControllerProxy)
        .EMISSION_MANAGER();
      assertEq(
        rewardsControllerAdmin,
        report.emissionManager,
        'RewardsController Proxy EMISSION_MANAGER() does not match with deployed report.emissionManager'
      );
    }
    {
      address emissionManagerOwner = Ownable(report.emissionManager).owner();
      assertEq(
        emissionManagerOwner,
        roles.poolAdmin,
        'EmissionManager owner does not match with roles.poolAdmin'
      );
    }
    {
      address proxyAdmin = address(uint160(uint256(vm.load(report.treasury, ADMIN_SLOT))));
      address owner = Ownable(proxyAdmin).owner();
      assertEq(
        owner,
        roles.poolAdmin,
        'Treasury proxy admin does not match with report.proxyAdmin'
      );
    }
  }

  function testCheckPermissionsTreasuryPartner() public {
    bytes32 emptyBytes;
    address marketOwner = makeAddr('MARKET_OWNER');
    address emergencyAdmin = makeAddr('EMERGENCY_ADMIN');
    address poolAdmin = makeAddr('POOL_ADMIN');
    address treasuryPartner = makeAddr('TREASURY_PARTNER');
    address deployer = msg.sender;
    (
      Roles memory roles,
      MarketConfig memory config,
      DeployFlags memory flags,
      MarketReport memory deployedContracts
    ) = _getMarketInput(marketOwner);

    roles.emergencyAdmin = emergencyAdmin;
    roles.poolAdmin = poolAdmin;

    config.paraswapAugustusRegistry = address(new AugustusRegistryMock());
    config.wrappedNativeToken = address(new WETH9());
    config.treasuryPartner = treasuryPartner;
    config.treasurySplitPercent = 5000;

    MarketReport memory report = deployAaveV3Testnet(
      deployer,
      roles,
      config,
      flags,
      deployedContracts
    );

    ACLManager aclManager = ACLManager(
      IPoolAddressesProvider(report.poolAddressesProvider).getACLManager()
    );

    {
      address providerOwner = Ownable(report.poolAddressesProvider).owner();
      assertEq(
        providerOwner,
        roles.marketOwner,
        'PoolAddressesProvider owner must be roles.marketOwner'
      );
    }
    {
      address providerRegistryOwner = Ownable(report.poolAddressesProviderRegistry).owner();
      assertEq(
        providerRegistryOwner,
        roles.marketOwner,
        'PoolAddressesProviderRegistry owner must be roles.marketOwner'
      );
    }
    {
      address providerAclAdmin = IPoolAddressesProvider(report.poolAddressesProvider).getACLAdmin();
      assertEq(
        providerAclAdmin,
        roles.poolAdmin,
        'PoolAddressesProvider.getACLAdmin() must be pool admin'
      );
    }
    {
      bool isPoolAdminDefaultAdmin = aclManager.hasRole(emptyBytes, roles.poolAdmin);
      assertTrue(isPoolAdminDefaultAdmin, 'roles.PoolAdmin must be default admin');
    }
    {
      bool isPoolAdminCorrect = aclManager.isPoolAdmin(roles.poolAdmin);
      assertTrue(isPoolAdminCorrect, 'roles.PoolAdmin must be pool admin');
    }
    {
      bool isEmergencyAdminCorrect = aclManager.isEmergencyAdmin(roles.emergencyAdmin);
      assertTrue(isEmergencyAdminCorrect, 'roles.emergencyAdmin must be emergency admin');
    }
    {
      bool isDeployerDefaultAdmin = aclManager.hasRole(emptyBytes, deployer);
      assertFalse(isDeployerDefaultAdmin, 'Deployer should not be default admin');
    }
    {
      bool isDeployerPoolAdmin = aclManager.isPoolAdmin(deployer);
      assertFalse(isDeployerPoolAdmin, 'deployer should not be pool admin');
    }
    {
      bool isDeployerEmergencyAdmin = aclManager.isEmergencyAdmin(deployer);
      assertFalse(isDeployerEmergencyAdmin, 'Deployer should not be emergency admin');
    }
    {
      bool isDeployerAssetListAdmin = aclManager.isAssetListingAdmin(deployer);
      assertFalse(isDeployerAssetListAdmin, 'Deployer should not be listing admin');
    }
    {
      address paraswapSwapAdapterOwner = Ownable(report.paraSwapLiquiditySwapAdapter).owner();
      address paraswapRepayAdapterOwner = Ownable(report.paraSwapRepayAdapter).owner();
      address paraswapWithdrawSwapOwner = Ownable(report.paraSwapWithdrawSwapAdapter).owner();
      assertEq(
        paraswapRepayAdapterOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap repay owner'
      );
      assertEq(
        paraswapSwapAdapterOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap liquidity swap owner'
      );
      assertEq(
        paraswapWithdrawSwapOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be paraswap withdraw swap owner'
      );
    }
    {
      address wethGatewayOwner = Ownable(report.wrappedTokenGateway).owner();
      assertEq(
        wethGatewayOwner,
        roles.poolAdmin,
        'roles.poolAdmin must be WrappedTokenGateway owner'
      );
    }
    {
      address rewardsControllerAdmin = RewardsController(report.rewardsControllerProxy)
        .EMISSION_MANAGER();
      assertEq(
        rewardsControllerAdmin,
        report.emissionManager,
        'RewardsController Proxy EMISSION_MANAGER() does not match with deployed report.emissionManager'
      );
    }
    {
      address emissionManagerOwner = Ownable(report.emissionManager).owner();
      assertEq(
        emissionManagerOwner,
        roles.poolAdmin,
        'EmissionManager owner does not match with roles.poolAdmin'
      );
    }
    {
      address proxyAdmin = address(uint160(uint256(vm.load(report.treasury, ADMIN_SLOT))));
      address owner = Ownable(proxyAdmin).owner();
      assertEq(
        owner,
        roles.poolAdmin,
        'Treasury proxy admin does not match with report.proxyAdmin'
      );
    }
    {
      address revenueSplitterPartnerA = IRevenueSplitter(report.revenueSplitter).RECIPIENT_A();
      address revenueSplitterPartnerB = IRevenueSplitter(report.revenueSplitter).RECIPIENT_B();
      assertEq(
        revenueSplitterPartnerA,
        report.treasury,
        'RevenueSplitter recipient A does not match report.treasury'
      );
      assertEq(
        revenueSplitterPartnerB,
        config.treasuryPartner,
        'RevenueSplitter recipient B does not match report.treasuryPartner'
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC721} from '@openzeppelin/token/ERC721/IERC721.sol';
import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts} from 'src/CryptoAnts.sol';
import {CryptoAnts} from 'src/CryptoAnts.sol';
import {Egg} from 'src/Egg.sol';
import {Governance} from 'src/Governance.sol';
import {ICryptoAnts} from 'src/ICryptoAnts.sol';
import {IEgg} from 'src/IEgg.sol';
import {IGovernance} from 'src/IGovernance.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract UnitTest is Test, TestUtils {
  uint256 internal constant _FORK_BLOCK = 7_117_514;
  ICryptoAnts internal _cryptoAnts;
  CryptoAnts internal _cryptoAntsContract;
  IGovernance internal _governance;
  Governance internal _governanceContract;
  address internal _owner = makeAddr('owner');
  IEgg internal _eggs;
  address private _randomAddress = makeAddr('randomAddress');
  address private _governorAddress = makeAddr('governorAddress');

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), _FORK_BLOCK);
    _eggs = IEgg(vm.computeCreateAddress(address(this), 2));
    _cryptoAntsContract = new CryptoAnts(address(_eggs), _governorAddress);
    _cryptoAnts = ICryptoAnts(_cryptoAntsContract);
    _governanceContract = Governance(address(_cryptoAnts));
    _governance = IGovernance(_governanceContract);
    _eggs = new Egg(address(_cryptoAnts));
  }

  function testOnlyAntCanBurnEgg() public {
    vm.expectRevert(IEgg.EggUnAuthorizedAccess.selector);
    _eggs.burn(_randomAddress, 1);
  }

  function testAntDeploymentChecksGovernorAddress() public {
    vm.expectRevert(IGovernance.ZeroAddressError.selector);
    new CryptoAnts(address(_eggs), address(0));
    vm.expectRevert(IGovernance.ZeroAddressError.selector);
    new CryptoAnts(address(0), address(_governorAddress));
  }

  function testEggDeploymentIsCryptoAntsDeployed() public {
    vm.expectRevert(IEgg.NoContractAccount.selector);
    new Egg(makeAddr('empty'));
    new Egg(address(_cryptoAnts));
  }

  function testOnlyCryptoAntCanMintEgg() public {
    vm.startPrank(_randomAddress);

    vm.expectRevert(IEgg.OnlyAntCanLayEgg.selector);
    _eggs.mint(_randomAddress, 1);

    vm.deal(_randomAddress, 1 ether);
    uint8 amountOfEggsToBuy = 100;
    _cryptoAnts.buyEggs{value: 1 ether}(amountOfEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.totalSupply(), amountOfEggsToBuy, 'Egg count should be 1 after minting from CryptoAnts');
    assertEq(_eggs.balanceOf(_randomAddress), amountOfEggsToBuy);
  }

  function testBuyEggsEmitEvents() public {
    vm.startPrank(_randomAddress);

    vm.deal(_randomAddress, 1 ether);
    uint8 amountOfEggsToBuy = 100;
    uint256 amountOfETH = 1 ether;

    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.EggsBought(_randomAddress, amountOfEggsToBuy);

    _cryptoAnts.buyEggs{value: amountOfETH}(amountOfEggsToBuy);

    vm.stopPrank();
  }

  function testBuyEggsValidatesBuyerBalance() public {
    uint8 amountOfEggsToBuy = 100;
    deal(_randomAddress, 0.9 ether); // not enough to buy 100 Egg.
    vm.startPrank(_randomAddress);

    vm.expectRevert(ICryptoAnts.WrongEtherSent.selector);
    _cryptoAnts.buyEggs(amountOfEggsToBuy);
    vm.stopPrank();
  }

  function testBuyEggsValidateInput() public {
    uint8 invalidAmountOfEggsToBuy = 0;
    hoax(_randomAddress, 1 ether);
    vm.expectRevert(ICryptoAnts.NoZeroAmount.selector);
    _cryptoAnts.buyEggs{value: 1 ether}(invalidAmountOfEggsToBuy);
  }

  function testBuyEggsReturnExtraETHToBuyer() public {
    uint8 amountOfEggsToBuy = 10; // 0.1 ETH
    uint256 expectedReturnValue = 0.9 ether;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(amountOfEggsToBuy);
    vm.stopPrank();

    assertEq(_randomAddress.balance, expectedReturnValue);

    hoax(address(this), 1 ether);
    vm.expectRevert();
    _cryptoAnts.buyEggs{value: 1 ether}(amountOfEggsToBuy);
  }

  function testBuyEggsValidateEggSupply() public {
    uint8 amountOfExpectedEggsToBuy = 100;
    uint256 amountOfETH = 1 ether;
    deal(_randomAddress, amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: amountOfETH}(amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(address(_cryptoAnts)), 0);
    assertEq(_eggs.balanceOf(_randomAddress), amountOfExpectedEggsToBuy);
    assertEq(_eggs.balanceOf(_randomAddress), _eggs.totalSupply());
    assertEq(address(_cryptoAnts).balance, amountOfETH);
  }

  function testCreateNewAntRequiresEgg() public {
    vm.expectRevert(ICryptoAnts.NoEggs.selector);
    _cryptoAnts.createAnt();
  }

  function testGetOwnedAntIds() public {
    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();

    uint256[] memory myAnts = _cryptoAnts.getMyAntsId();
    assertEq(myAnts.length, 1);
    vm.stopPrank();
  }

  function testGetOwnedAntIdsAfterDelete() public {
    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(2);
    _cryptoAnts.createAnt();
    _cryptoAnts.createAnt();

    uint256[] memory myAnts = _cryptoAnts.getMyAntsId();
    assertEq(myAnts.length, 2);

    uint256 firstAntId = myAnts[0];
    uint256 secondAntId = myAnts[1];

    _cryptoAnts.sellAnt(firstAntId);

    uint256[] memory myAntsAfterDelete = _cryptoAnts.getMyAntsId();
    assertEq(myAntsAfterDelete.length, 1);
    assertEq(myAntsAfterDelete[0], secondAntId);

    vm.stopPrank();
  }

  function testCreateNewAntEmits() public {
    uint256 antId = _cryptoAntsContract.antsCreated() + 1;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.AntCreated(antId);
    _cryptoAnts.createAnt();
    vm.stopPrank();
  }

  function testCreateNewAntBurnsEgg() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    _cryptoAnts.createAnt();
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), 0);
  }

  function testCreateBatchAntRequiresEgg() public {
    vm.expectRevert(ICryptoAnts.NoEnoughEggs.selector);
    _cryptoAnts.createAntInBatch(10);
  }

  function testCreateBatchAntEmits() public {
    uint256 antId = _cryptoAntsContract.antsCreated() + 1;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(2);
    assertEq(_eggs.balanceOf(_randomAddress), 2);
    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.AntCreated(antId);
    _cryptoAnts.createAntInBatch(2);
    vm.stopPrank();
  }

  function testCreateBatchAntBurnsEgg() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(100);
    assertEq(_eggs.balanceOf(_randomAddress), 100);
    _cryptoAnts.createAntInBatch(100);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), 0);
  }

  function testANTCanOnlyBeSoldByTheOwner() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    uint256 antId = _cryptoAntsContract.antsCreated();
    vm.stopPrank();

    vm.expectRevert(ICryptoAnts.AntUnAuthorizedAccess.selector);
    _cryptoAnts.sellAnt(antId);

    vm.startPrank(_randomAddress);
    _cryptoAnts.sellAnt(antId);
    vm.stopPrank();
  }

  function testANTSellEmit() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint256 antId = _cryptoAntsContract.antsCreated();

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntSold(_randomAddress, antId);

    _cryptoAnts.sellAnt(antId);
    vm.stopPrank();
  }

  function testANTCanBeSoldForLessETHThanTheEGGPrice() public {
    uint256 initialBalance = 1 ether;
    deal(_randomAddress, initialBalance);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: initialBalance}(1);

    _cryptoAnts.createAnt();
    uint256 antId = _cryptoAntsContract.antsCreated();

    uint256 beforeSellBalance = _randomAddress.balance;

    _cryptoAnts.sellAnt(antId);

    uint256 afterSellBalance = _randomAddress.balance;

    assertEq(afterSellBalance, beforeSellBalance + _governanceContract.antPrice());

    vm.stopPrank();
  }

  function testBurnTheAntAfterTheUserSellsIt() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    uint256 antId = _cryptoAntsContract.antsCreated();
    assertEq(_cryptoAnts.ownerOf(antId), _randomAddress);

    vm.expectEmit(true, true, true, true);
    emit IERC721.Transfer(_randomAddress, address(0), antId);
    _cryptoAnts.sellAnt(antId);

    vm.expectRevert(ICryptoAnts.AntUnAuthorizedAccess.selector);
    _cryptoAnts.sellAnt(antId);

    vm.stopPrank();
  }

  function testsetEggPrice() public {
    vm.prank(_governorAddress);
    _governance.setEggPrice(1 ether);

    vm.prank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    assertEq(_randomAddress.balance, 0);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    assertEq(_cryptoAnts.getContractBalance(), 1 ether);
  }

  function testsetEggPriceEmits() public {
    vm.prank(_governorAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.setEggPrice(1 ether);
  }

  function testsetAntPriceEmits() public {
    vm.prank(_governorAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.AntPriceChanged(0.004 ether);
    _governance.setAntPrice(0.004 ether);
  }

  function testsetEggLayingCooldownEmits() public {
    vm.startPrank(_governorAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggLayingCooldownChanged(1 seconds);
    _governance.setEggLayingCooldown(1 seconds);
    vm.stopPrank();
  }

  function testLayEgg() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint256 firstAntId = _cryptoAntsContract.antsCreated();
    vm.expectEmit(true, false, false, false);
    emit ICryptoAnts.EggsLayed(_randomAddress, 0);
    _cryptoAnts.layEgg(firstAntId);

    uint256 amountOflayedEggs = _eggs.balanceOf(_randomAddress);
    require(0 <= amountOflayedEggs && amountOflayedEggs <= 20, 'Invalid egg count');

    vm.stopPrank();
  }

  function testLayEggCooldown() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint256 firstAntId = _cryptoAntsContract.antsCreated();
    _cryptoAnts.layEgg(firstAntId);

    vm.expectRevert(ICryptoAnts.CoolingDown.selector);
    _cryptoAnts.layEgg(firstAntId);
    vm.stopPrank();
  }

  function testLayEggAntDeathProbabilityCorrectness() public {
    vm.prank(_governorAddress);
    vm.expectRevert(IGovernance.ValidInput0UpTo100.selector);
    _governance.setAntDeathProbability(101);
    vm.stopPrank();
  }

  function testLayEggAntDeath() public {
    vm.prank(_governorAddress);
    _governance.setAntDeathProbability(100);

    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint256 firstAntId = _cryptoAntsContract.antsCreated();

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntDied(_randomAddress, firstAntId);

    _cryptoAnts.layEgg(firstAntId);

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    // The Ant is dead! there is no Ant you own, so:
    vm.expectRevert(ICryptoAnts.AntUnAuthorizedAccess.selector);
    _cryptoAnts.layEgg(firstAntId);
    vm.stopPrank();
  }

  function testLayEggAccessControl() public {
    uint256 firstAntId = _cryptoAntsContract.antsCreated();
    vm.expectRevert(ICryptoAnts.AntUnAuthorizedAccess.selector);
    _cryptoAnts.layEgg(firstAntId);
  }

  function testGovernanceAccessControl() public {
    vm.expectRevert(IGovernance.GovUnAuthorizedAccess.selector);
    _governance.setEggPrice(1 ether);
    vm.expectRevert(IGovernance.GovUnAuthorizedAccess.selector);
    _governance.setAntPrice(0.004 ether);
    vm.expectRevert(IGovernance.GovUnAuthorizedAccess.selector);
    _governance.setEggLayingCooldown(1 seconds);
    vm.expectRevert(IGovernance.GovUnAuthorizedAccess.selector);
    _governance.setAntDeathProbability(1);

    vm.prank(_governorAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.setEggPrice(1 ether);
  }

  function testIsAntAlive() public {
    vm.startPrank(_randomAddress);

    uint256 nonExistentAntId = _cryptoAntsContract.antsCreated() + 1;

    assertEq(_cryptoAnts.isAntAlive(nonExistentAntId), false);
    deal(_randomAddress, 1 ether);

    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    uint256 justCreatedAntId = nonExistentAntId;
    assertEq(_cryptoAnts.isAntAlive(justCreatedAntId), true);

    vm.stopPrank();
  }

  function testAdminBackdoor() public {
    _cryptoAnts._adminMintAnt(10);
  }

  function testEggIsNotDivisable() public view {
    assertEq(_eggs.decimals(), 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IERC721} from '@openzeppelin/token/ERC721/IERC721.sol';
import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts} from 'src/CryptoAnts.sol';
import {Egg} from 'src/Egg.sol';
import {ICryptoAnts} from 'src/ICryptoAnts.sol';
import {IEgg} from 'src/IEgg.sol';
import {IGovernance} from 'src/IGovernance.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract UnitTest is Test, TestUtils {
  uint256 internal constant _FORK_BLOCK = 7_117_514;
  ICryptoAnts internal _cryptoAnts;
  IGovernance internal _governance;
  address internal _owner = makeAddr('owner');
  IEgg internal _eggs;
  address private _randomAddress = makeAddr('randomAddress');
  address private _governerAddress = makeAddr('governerAddress');

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), _FORK_BLOCK);
    _eggs = IEgg(vm.computeCreateAddress(address(this), 2));
    _cryptoAnts = new CryptoAnts(address(_eggs), _governerAddress);
    _governance = IGovernance(address(_cryptoAnts));
    _eggs = new Egg(address(_cryptoAnts));
  }

  function testOnlyAntCanBurnEgg() public {
    vm.expectRevert('Only CryptoAnts can burn eggs');
    _eggs.burn(_randomAddress, 1);
  }

  function testAntDeploymentChecksGovernorAddress() public {
    vm.expectRevert('No Governor set!');
    new CryptoAnts(address(_eggs), address(0));
  }

  function testEggDeploymentIsCryptoAntsDeployed() public {
    vm.expectRevert('Invalid Ants');
    new Egg(makeAddr('empty'));
    new Egg(address(_cryptoAnts));
  }

  function testOnlyCryptoAntCanMintEgg() public {
    vm.startPrank(_randomAddress);

    vm.expectRevert('Only CryptoAnts can mint eggs');
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
    vm.expectRevert('Amount must be greater than zero');
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
    vm.expectRevert('Failed to return extra ETH');
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

  function testCreateNewAntEmits() public {
    uint256 expectedAntId = 1;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.AntCreated(expectedAntId);
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

  function testANTCanOnlyBeSoldByTheOwner() public {
    uint8 expectedAntId = 1;

    vm.expectRevert('Unauthorized');
    _cryptoAnts.sellAnt(expectedAntId);

    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    _cryptoAnts.sellAnt(expectedAntId);
    vm.stopPrank();
  }

  function testANTSellEmit() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint8 expectedAntId = 1;

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntSold(_randomAddress, expectedAntId);

    _cryptoAnts.sellAnt(expectedAntId);
    vm.stopPrank();
  }

  function testANTCanBeSoldForLessETHThanTheEGGPrice() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    uint8 expectedAntId = 1;

    _cryptoAnts.createAnt();

    uint256 beforeSellBalance = _randomAddress.balance;

    _cryptoAnts.sellAnt(expectedAntId);

    uint256 afterSellBalance = _randomAddress.balance;

    // 0.004 * 1e18 = 4000000000000000
    assertEq(afterSellBalance, beforeSellBalance + 4_000_000_000_000_000);

    vm.stopPrank();
  }

  function testBurnTheAntAfterTheUserSellsIt() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    uint8 expectedAntId = 1;

    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    assertEq(_cryptoAnts.ownerOf(expectedAntId), _randomAddress);

    vm.expectEmit(true, true, true, true);
    emit IERC721.Transfer(_randomAddress, address(0), expectedAntId);
    _cryptoAnts.sellAnt(expectedAntId);

    vm.expectRevert('Unauthorized');
    _cryptoAnts.sellAnt(expectedAntId);

    vm.stopPrank();
  }

  function testsetEggPrice() public {
    vm.prank(_governerAddress);
    _governance.setEggPrice(1 ether);

    vm.prank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    assertEq(_randomAddress.balance, 0);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    assertEq(_cryptoAnts.getContractBalance(), 1 ether);
  }

  function testsetEggPriceEmits() public {
    vm.prank(_governerAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.setEggPrice(1 ether);
  }

  function testsetEggLayingCooldownEmits() public {
    vm.startPrank(_governerAddress);
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

    uint8 firstAntId = 1;
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

    uint8 firstAntId = 1;
    _cryptoAnts.layEgg(firstAntId);

    vm.expectRevert('cooldowning...');
    _cryptoAnts.layEgg(firstAntId);
    vm.stopPrank();
  }

  function testLayEggAntDeathProbabilityCorrectness() public {
    vm.prank(_governerAddress);
    vm.expectRevert('Probability must be between 0 and 100');
    _governance.setAntDeathProbability(101);
    vm.stopPrank();
  }

  function testLayEggAntDeath() public {
    vm.prank(_governerAddress);
    _governance.setAntDeathProbability(100);

    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint8 firstAntId = 1;

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntDied(_randomAddress, firstAntId);

    _cryptoAnts.layEgg(firstAntId);

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    // The Ant is dead! there is no Ant you own, so:
    vm.expectRevert('Unauthorized');
    _cryptoAnts.layEgg(firstAntId);
    vm.stopPrank();
  }

  function testLayEggAccessControl() public {
    uint8 firstAntId = 1;
    vm.expectRevert('Unauthorized');
    _cryptoAnts.layEgg(firstAntId);
  }

  function testGovernanceAccessControl() public {
    vm.expectRevert('Unauthorized: Only governer');
    _governance.setEggPrice(1 ether);
    vm.expectRevert('Unauthorized: Only governer');
    _governance.setEggLayingCooldown(1 seconds);
    vm.expectRevert('Unauthorized: Only governer');
    _governance.setAntDeathProbability(1);

    vm.prank(_governerAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.setEggPrice(1 ether);
  }

  function testIsAntAlive() public {
    vm.startPrank(_randomAddress);

    assertEq(_cryptoAnts.isAntAlive(1), false);
    deal(_randomAddress, 1 ether);

    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_cryptoAnts.isAntAlive(1), false);

    vm.stopPrank();
  }

  function testEggIsNotDivisable() public view {
    assertEq(_eggs.decimals(), 0);
  }
}

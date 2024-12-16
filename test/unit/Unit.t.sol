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

  function testEggIsNotDivisable() public view {
    assertEq(_eggs.decimals(), 0);
  }

  function testOnlyAntCanBurnEgg() public {
    vm.expectRevert('Only CryptoAnts can burn eggs');
    _eggs.burn(_randomAddress, 1);
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
    uint8 __amountOfEggsToBought = 100;
    _cryptoAnts.buyEggs{value: 1 ether}(__amountOfEggsToBought);
    vm.stopPrank();

    assertEq(_eggs.totalSupply(), __amountOfEggsToBought, 'Egg count should be 1 after minting from CryptoAnts');

    uint256 __balanceOfBuyer = _eggs.balanceOf(_randomAddress);
    assertEq(__balanceOfBuyer, __amountOfEggsToBought);
  }

  function testBuyEggsEmitEvents() public {
    vm.startPrank(_randomAddress);

    vm.deal(_randomAddress, 1 ether);
    uint8 __amountOfEggsToBought = 100;
    uint256 __amountOfETH = 1 ether;

    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.EggsBought(_randomAddress, __amountOfEggsToBought);

    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfEggsToBought);

    vm.stopPrank();
  }

  function testBuyEggsValidatesBuyerBalance() public {
    uint8 __amountOfEggsToBuy = 100;
    deal(_randomAddress, 0.9 ether); // not enough to buy 100 Egg.
    vm.startPrank(_randomAddress);

    vm.expectRevert(ICryptoAnts.WrongEtherSent.selector);
    _cryptoAnts.buyEggs(__amountOfEggsToBuy);
    vm.stopPrank();
  }

  function testBuyEggsValidateInput() public {
    uint8 __invalidAmountOfEggsToBuy = 0;
    hoax(_randomAddress, 1 ether);
    vm.expectRevert('Amount must be greater than zero');
    _cryptoAnts.buyEggs{value: 1 ether}(__invalidAmountOfEggsToBuy);
  }

  function testBuyEggsReturnExtraETHToBuyer() public {
    uint8 __amountOfEggsToBuy = 10; // 0.1 ETH
    uint256 __expectedReturnValue = 0.9 ether;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(__amountOfEggsToBuy);
    vm.stopPrank();

    assertEq(_randomAddress.balance, __expectedReturnValue);

    hoax(address(this), 1 ether);
    vm.expectRevert('Failed to return extra ETH');
    _cryptoAnts.buyEggs{value: 1 ether}(__amountOfEggsToBuy);
  }

  function testBuyEggsValidateEggSupply() public {
    uint8 __amountOfExpectedEggsToBuy = 100;
    uint256 __amountOfETH = 1 ether;
    deal(_randomAddress, __amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(address(_cryptoAnts)), 0);
    assertEq(_eggs.balanceOf(_randomAddress), __amountOfExpectedEggsToBuy);
    assertEq(_eggs.balanceOf(_randomAddress), _eggs.totalSupply());
    assertEq(address(_cryptoAnts).balance, __amountOfETH);
  }

  function testCreateNewAntRequiresEgg() public {
    deal(address(this), 1 ether);
    vm.expectRevert(ICryptoAnts.NoEggs.selector);
    _cryptoAnts.createAnt{value: 1 ether}();
  }

  function testCreateNewAntEmits() public {
    uint256 __expectedAntId = 1;
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.AntCreated(__expectedAntId);
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
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    uint8 _expectedAntId = 1;
    vm.stopPrank();

    hoax(makeAddr('nonOwnerAddress'), 1 ether);
    vm.expectRevert('Unauthorized');
    _cryptoAnts.sellAnt(_expectedAntId);
  }

  function testANTSellEmit() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);

    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint8 _expectedAntId = 1;

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntSold(_randomAddress, _expectedAntId);

    _cryptoAnts.sellAnt(_expectedAntId);
    vm.stopPrank();
  }

  function testANTCanBeSoldForLessETHThanTheEGGPrice() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    uint8 _expectedAntId = 1;

    _cryptoAnts.createAnt();

    uint256 _beforeSellBalance = _randomAddress.balance;

    _cryptoAnts.sellAnt(_expectedAntId);

    uint256 _afterSellBalance = _randomAddress.balance;

    // 0.004 * 1e18 = 4000000000000000
    assertEq(_afterSellBalance, _beforeSellBalance + 4_000_000_000_000_000);

    vm.stopPrank();
  }

  function testBurnTheAntAfterTheUserSellsIt() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    uint8 _expectedAntId = 1;

    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    assertEq(_cryptoAnts.ownerOf(_expectedAntId), _randomAddress);

    vm.expectEmit(true, true, true, true);
    emit IERC721.Transfer(_randomAddress, address(0), _expectedAntId);
    _cryptoAnts.sellAnt(_expectedAntId);

    vm.expectRevert('Unauthorized');
    _cryptoAnts.sellAnt(_expectedAntId);

    vm.stopPrank();
  }

  function testChangeEggPrice() public {
    vm.prank(_governerAddress);
    _governance.changeEggPrice(1 ether);

    vm.prank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    assertEq(_randomAddress.balance, 0);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
  }

  function testChangeEggPriceEmits() public {
    vm.prank(_governerAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.changeEggPrice(1 ether);
  }

  function testChangeEggLayingCooldownEmits() public {
    vm.startPrank(_governerAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggLayingCooldownChanged(1 seconds);
    _governance.changeEggLayingCooldown(1 seconds);
    vm.stopPrank();
  }

  function testLayEgg() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint8 _firstAntId = 1;
    vm.expectEmit(true, false, false, false);
    emit ICryptoAnts.EggsLayed(_randomAddress, 0);
    _cryptoAnts.layEgg(_firstAntId);
    vm.stopPrank();
  }

  function testLayEggCooldown() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    uint8 _firstAntId = 1;
    _cryptoAnts.layEgg(_firstAntId);

    vm.expectRevert('cooldowning...');
    _cryptoAnts.layEgg(_firstAntId);
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

    uint8 _firstAntId = 1;

    vm.expectEmit(true, true, false, true);
    emit ICryptoAnts.AntDied(_randomAddress, _firstAntId);

    _cryptoAnts.layEgg(_firstAntId);

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    // The Ant is dead! there is no Ant you own, so:
    vm.expectRevert('Unauthorized');
    _cryptoAnts.layEgg(_firstAntId);
    vm.stopPrank();
  }

  function testLayEggAccessControl() public {
    uint8 _firstAntId = 1;
    vm.expectRevert('Unauthorized');
    _cryptoAnts.layEgg(_firstAntId);
  }

  function testGovernanceAccessControl() public {
    vm.expectRevert('Unauthorized: Only governer');
    _governance.changeEggPrice(1 ether);
    vm.expectRevert('Unauthorized: Only governer');
    _governance.changeEggLayingCooldown(1 seconds);
    vm.expectRevert('Unauthorized: Only governer');
    _governance.setAntDeathProbability(1);

    vm.prank(_governerAddress);
    vm.expectEmit(false, false, false, true);
    emit IGovernance.EggPriceChanged(1 ether);
    _governance.changeEggPrice(1 ether);
  }
}

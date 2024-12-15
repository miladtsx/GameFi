// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts, ICryptoAnts} from 'src/CryptoAnts.sol';
import {Egg, IEgg} from 'src/Egg.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract UnitTest is Test, TestUtils {
  uint256 internal constant _FORK_BLOCK = 7_117_514;
  ICryptoAnts internal _cryptoAnts;
  address internal _owner = makeAddr('owner');
  IEgg internal _eggs;
  address _randomAddress = makeAddr('randomAddress');

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), _FORK_BLOCK);
    _eggs = IEgg(vm.computeCreateAddress(address(this), 2));
    _cryptoAnts = new CryptoAnts(address(_eggs));
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
}

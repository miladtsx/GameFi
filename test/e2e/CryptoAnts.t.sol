// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts, ICryptoAnts} from 'src/CryptoAnts.sol';
import {Egg, IEgg} from 'src/Egg.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract E2ECryptoAnts is Test, TestUtils {
  uint256 internal constant FORK_BLOCK = 7_117_514;
  ICryptoAnts internal _cryptoAnts;
  address internal _owner = makeAddr('owner');
  IEgg internal _eggs;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('sepolia'), FORK_BLOCK);
    _eggs = IEgg(vm.computeCreateAddress(address(this), 2));
    _cryptoAnts = new CryptoAnts(address(_eggs));
    _eggs = new Egg(address(_cryptoAnts));
  }

  function test__BuyEggs_Only_CryptoAnt_Can_Mint_Egg() public {
    address __nonCryptoAntsAddress = makeAddr('nonCryptoAnts');
    vm.startPrank(__nonCryptoAntsAddress);

    vm.expectRevert('Only CryptoAnts can mint eggs');
    _eggs.mint(__nonCryptoAntsAddress, 1);

    vm.deal(__nonCryptoAntsAddress, 1 ether);
    uint8 __amountOfEggsToBought = 100;
    _cryptoAnts.buyEggs{value: 1 ether}(__amountOfEggsToBought);
    vm.stopPrank();

    assertEq(_eggs.totalSupply(), __amountOfEggsToBought, 'Egg count should be 1 after minting from CryptoAnts');

    uint256 __balanceOfBuyer = _eggs.balanceOf(__nonCryptoAntsAddress);
    assertEq(__balanceOfBuyer, __amountOfEggsToBought);
  }

  function test__BuyEggs_Should_Emit_Events() public {
    address __randomBuyerAddress = makeAddr('randomBuyerAddress');

    vm.startPrank(__randomBuyerAddress);

    vm.deal(__randomBuyerAddress, 1 ether);
    uint8 __amountOfEggsToBought = 100;
    uint256 __amountOfETH = 1 ether;

    vm.expectEmit(true, false, false, true);
    emit ICryptoAnts.EggsBought(__randomBuyerAddress, __amountOfEggsToBought);

    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfEggsToBought);

    vm.stopPrank();
  }

  function test__BuyEggs_Validate_Buyer_Balance() public {
    address lowBalanceAccount = makeAddr('lowBalanceAccount');
    uint8 __amountOfEggsToBuy = 100;
    deal(lowBalanceAccount, 0.9 ether); // not enough to buy 100 Egg.
    vm.startPrank(lowBalanceAccount);

    vm.expectRevert(ICryptoAnts.WrongEtherSent.selector);
    _cryptoAnts.buyEggs(__amountOfEggsToBuy);
    vm.stopPrank();
  }

  function test__BuyEggs_Validate_Egg_Supply() public {
    address __randomBuyerAccount = makeAddr('__randomBuyerAccount');
    uint8 __amountOfExpectedEggsToBuy = 100;
    uint256 __amountOfETH = 1 ether;
    deal(__randomBuyerAccount, __amountOfETH);

    vm.startPrank(__randomBuyerAccount);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(address(_cryptoAnts)), 0);
    assertEq(_eggs.balanceOf(address(__randomBuyerAccount)), __amountOfExpectedEggsToBuy);
    assertEq(_eggs.balanceOf(address(__randomBuyerAccount)), _eggs.totalSupply());
    assertEq(address(_cryptoAnts).balance, __amountOfETH);
  }

  function testBuyAnEggAndCreateNewAnt() public {}
  function testSendFundsToTheUserWhoSellsAnts() public {}
  function testBurnTheAntAfterTheUserSellsIt() public {}

  /*
    This is a completely optional test.
    Hint: you may need `warp` to handle the egg creation cooldown
  */
  function testBeAbleToCreate100AntsWithOnlyOneInitialEgg() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts, ICryptoAnts} from 'src/CryptoAnts.sol';
import {Egg, IEgg} from 'src/Egg.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract IntegrationTest is Test, TestUtils {
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

  function testBuyEGGWithETH() public {
    address __randomBuyerAccount = makeAddr('__randomBuyerAccount');
    uint8 __amountOfExpectedEggsToBuy = 100;
    uint256 __amountOfETH = 1 ether;
    deal(__randomBuyerAccount, __amountOfETH);

    vm.startPrank(__randomBuyerAccount);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(address(__randomBuyerAccount)), __amountOfExpectedEggsToBuy);
  }

  function testEGGCosts1CentETH() public {
    address __randomBuyerAccount = makeAddr('__randomBuyerAccount');
    uint8 __amountOfExpectedEggsToBuy = 200; // 200 * 0.01 = 2 ether
    uint256 __amountOfETH = 2 ether;
    deal(__randomBuyerAccount, __amountOfETH);

    vm.startPrank(__randomBuyerAccount);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(address(__randomBuyerAccount)), __amountOfExpectedEggsToBuy);
    assertEq(__randomBuyerAccount.balance, 0);
  }

  function testEGGCanBeUsedToCreateAnANT() public {}
  function testANTCanBeSoldForLessETHThanTheEGGPrice() public {}
  function testBuyAnEggAndCreateNewAnt() public {}
  function testSendFundsToTheUserWhoSellsAnts() public {}
  function testBurnTheAntAfterTheUserSellsIt() public {}
  function testAnts_should_be_able_to_create_lay_eggs_once_every_10_minutes() public {}
  function testAnts_should_create_random_eggs_ranging_0_to_20() public {}
  function testAnts_should_die_randomly_when_laying_eggs() public {}

  /*
    This is a completely optional test.
    Hint: you may need `warp` to handle the egg creation cooldown
  */
  function testBeAbleToCreate100AntsWithOnlyOneInitialEgg() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts} from 'src/CryptoAnts.sol';
import {Egg} from 'src/Egg.sol';

import {ICryptoAnts} from 'src/ICryptoAnts.sol';
import {IEgg} from 'src/IEgg.sol';
import {IGovernance} from 'src/IGovernance.sol';
import {TestUtils} from 'test/TestUtils.sol';

contract IntegrationTest is Test, TestUtils {
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

  function testBuyEGGWithETH() public {
    uint8 __amountOfExpectedEggsToBuy = 100;
    uint256 __amountOfETH = 1 ether;
    deal(_randomAddress, __amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), __amountOfExpectedEggsToBuy);

    assertEq(_cryptoAnts.getContractBalance(), __amountOfETH);
  }

  function testEGGCosts1CentETH() public {
    uint8 __amountOfExpectedEggsToBuy = 200; // 200 * 0.01 = 2 ether
    uint256 __amountOfETH = 2 ether;
    deal(_randomAddress, __amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: __amountOfETH}(__amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), __amountOfExpectedEggsToBuy);
    assertEq(_randomAddress.balance, 0);
  }

  function testEGGCanBeUsedToCreateAnANT() public {
    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    assertEq(_cryptoAnts.getAntsCreated(), 1);
  }

  function testANTCanBeSoldByTheOwner() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    uint8 _expectedAntId = 1;
    _cryptoAnts.createAnt();
    _cryptoAnts.sellAnt(_expectedAntId);
    vm.stopPrank();
  }

  function testGovernanceChangeEggPrice() public {
    vm.prank(_governerAddress);
    _governance.changeEggPrice(1 ether);

    vm.prank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_randomAddress.balance, 0);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
  }

  function testAntsShouldBeAbleToCreateLayEggsOnceEvery10Minutes() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    uint8 _firstAntId = 1;
    _cryptoAnts.layEgg(_firstAntId);

    vm.warp(block.timestamp + 9 minutes);

    vm.expectRevert('You must wait before laying another egg');
    _cryptoAnts.layEgg(_firstAntId);

    vm.warp(block.timestamp + 1 minutes);
    _cryptoAnts.layEgg(_firstAntId);

    vm.stopPrank();
  }

  function testAntsShouldCreateRandomEggsRanging0To20() public {
    vm.prank(_governerAddress);
    _governance.changeEggLayingCooldown(0);

    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    uint8 _firstAntId = 1;

    for (uint256 i = 0; i < 100; i++) {
      uint256 __preLayEggBalance = _eggs.balanceOf(_randomAddress);
      _cryptoAnts.layEgg(_firstAntId);

      uint256 __postLayEggBalance = _eggs.balanceOf(_randomAddress);

      uint8 _amountOflayedEggs = uint8(__postLayEggBalance - __preLayEggBalance);

      require(_amountOflayedEggs >= 0 && _amountOflayedEggs <= 20, 'Number of laid eggs must be between 0 and 20');
    }
    vm.stopPrank();
  }

  function testAnts_should_die_randomly_when_laying_eggs() public {}

  /*
    This is a completely optional test.
    Hint: you may need `warp` to handle the egg creation cooldown
  */
  function testBeAbleToCreate100AntsWithOnlyOneInitialEgg() public {}
}

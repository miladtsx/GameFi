// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {CryptoAnts} from 'src/CryptoAnts.sol';
import {Egg} from 'src/Egg.sol';
import {Governance} from 'src/Governance.sol';
import {ICryptoAnts} from 'src/ICryptoAnts.sol';
import {IEgg} from 'src/IEgg.sol';
import {IGovernance} from 'src/IGovernance.sol';
import {TestUtils} from 'test/TestUtils.sol';

// Helper Struct added for readability of the testCanCreate100AntsFromOneEgg
struct AntStats {
  uint256 totalAnts;
  uint256 aliveAnts;
  uint256 eggsLayed;
  uint256 antsBorn;
  uint256 antsDied;
  uint256 noEggLays;
}

contract IntegrationTest is Test, TestUtils {
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

  function testMintAntForAdmin() public {
    _cryptoAnts._adminMintAnt(800);
  }

  function testBuyEGGWithETH() public {
    uint8 amountOfExpectedEggsToBuy = 100;
    uint256 amountOfETH = 1 ether;
    deal(_randomAddress, amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: amountOfETH}(amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), amountOfExpectedEggsToBuy);

    assertEq(_cryptoAnts.getContractBalance(), amountOfETH);
  }

  function testEGGCosts1CentETH() public {
    uint8 amountOfExpectedEggsToBuy = 200; // 200 * 0.01 = 2 ether
    uint256 amountOfETH = 2 ether;
    deal(_randomAddress, amountOfETH);

    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: amountOfETH}(amountOfExpectedEggsToBuy);
    vm.stopPrank();

    assertEq(_eggs.balanceOf(_randomAddress), amountOfExpectedEggsToBuy);
    assertEq(_randomAddress.balance, 0);
  }

  function testEGGCanBeUsedToCreateAnANT() public {
    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    uint256 preCreationCount = _cryptoAntsContract.antsCreated();

    _cryptoAnts.createAnt();

    uint256 postCreationCount = _cryptoAntsContract.antsCreated();
    assertEq(postCreationCount, preCreationCount + 1);
  }

  function testEGGCanBeUsedToCreateAnANTInBatch() public {
    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(100);

    uint256 _countOfEgg = _eggs.balanceOf(_randomAddress);

    _cryptoAnts.createAntInBatch(uint8(_countOfEgg));

    uint256[] memory _countOfAntsIOwn = _cryptoAnts.getMyAntsId();
    assertEq(_countOfEgg, _countOfAntsIOwn.length);
    assertEq(_eggs.balanceOf(_randomAddress), 0);
  }

  function testANTCanBeSoldByTheOwner() public {
    deal(_randomAddress, 1 ether);
    vm.startPrank(_randomAddress);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    uint256 antId = _cryptoAntsContract.antsCreated();
    _cryptoAnts.sellAnt(antId);
    vm.stopPrank();
  }

  function testGovernancesetEggPrice() public {
    vm.prank(_governorAddress);
    _governance.setEggPrice(1 ether);

    vm.prank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    assertEq(_randomAddress.balance, 0);
    assertEq(_eggs.balanceOf(_randomAddress), 1);
  }

  function testGovernancesetAntPrice() public {
    uint8 countOfEggToBuy = 1;

    vm.prank(_governorAddress);
    _governance.setEggPrice(1 ether);
    vm.prank(_governorAddress);
    _governance.setAntPrice(1 ether);

    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(countOfEggToBuy);
    assertEq(_randomAddress.balance, 1 ether - _governanceContract.eggPrice());
    assertEq(_eggs.balanceOf(_randomAddress), countOfEggToBuy);
    _cryptoAnts.createAnt();

    uint256 antId = _cryptoAntsContract.antsCreated();

    _cryptoAnts.sellAnt(antId);

    assertEq(_randomAddress.balance, 1 ether);
    vm.stopPrank();
  }

  function testAntsShouldBeAbleToCreateLayEggsOnceEvery10Minutes() public {
    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    uint256 firstAntId = _cryptoAntsContract.antsCreated();
    _cryptoAnts.layEgg(firstAntId);

    vm.warp(block.timestamp + _governanceContract.EGG_LAYING_COOLDOWN() - 1);

    vm.expectRevert(ICryptoAnts.CoolingDown.selector);
    _cryptoAnts.layEgg(firstAntId);

    vm.warp(block.timestamp + 1);
    _cryptoAnts.layEgg(firstAntId);

    vm.stopPrank();
  }

  function testAntsShouldCreateRandomEggsRanging0To20() public {
    vm.prank(_governorAddress);
    _governance.setEggLayingCooldown(0);

    vm.startPrank(_randomAddress);

    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);

    _cryptoAnts.createAnt();

    assertEq(_eggs.balanceOf(_randomAddress), 0);

    uint256 firstAntId = _cryptoAntsContract.antsCreated();

    for (uint256 i = 0; i < 100; i++) {
      uint256 preLayEggBalance = _eggs.balanceOf(_randomAddress);
      _cryptoAnts.layEgg(firstAntId);

      uint256 postLayEggBalance = _eggs.balanceOf(_randomAddress);

      uint8 _amountOflayedEggs = uint8(postLayEggBalance - preLayEggBalance);
      require(0 <= _amountOflayedEggs && _amountOflayedEggs <= 20, 'Invalid egg count');
    }
    vm.stopPrank();
  }

  /**
   * Simulating multiple egg laying attempts to test the randomness of ant death
   */
  function testAntsShouldDieRandomlyWhenLayingEggs() public {
    // Setting up the test environment
    vm.startPrank(_governorAddress);
    _governance.setEggLayingCooldown(0); // Setting cooldown to 0 for testing purposes
    _governance.setAntDeathProbability(80); // Increase the chance of Ant laying death to 80%
    vm.stopPrank();

    vm.startPrank(_randomAddress);
    deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
    uint256 antId = _cryptoAntsContract.antsCreated();

    bool didAntDied = false;

    for (uint8 i = 0; i < 100; i++) {
      _cryptoAnts.layEgg(antId);

      //Checking if the ant has died
      if (_cryptoAntsContract.antToOwner(antId) == address(0)) {
        assertEq(_cryptoAntsContract.antToOwner(antId), address(0), 'Ant should have died');
        didAntDied = true;
        break;
      }
    }

    assertEq(didAntDied, true, 'Ant never died');

    vm.stopPrank();
  }

  function testCanCreate100AntsFromOneEgg() public {
    uint8 targetAntCount = 100;

    _setupInitialState();

    AntStats memory stats = _initializeAntStats();

    while (stats.totalAnts < targetAntCount && stats.aliveAnts > 0) {
      stats = _layEggsAndCreateAnts(stats, targetAntCount);
    }

    _logAntJourney(stats);
    vm.stopPrank();
  }

  function _setupInitialState() internal {
    vm.startPrank(_randomAddress);
    vm.deal(_randomAddress, 1 ether);
    _cryptoAnts.buyEggs{value: 1 ether}(1);
    _cryptoAnts.createAnt();
  }

  function _layEggsAndCreateAnts(AntStats memory stats, uint256 targetCount) internal returns (AntStats memory) {
    for (uint8 antId = uint8(_cryptoAntsContract.antsCreated()); antId <= stats.totalAnts; antId++) {
      if (stats.aliveAnts >= targetCount) break;

      _cryptoAnts.layEgg(antId);

      uint8 eggsCount = uint8(_eggs.balanceOf(_randomAddress));
      stats.eggsLayed += eggsCount;

      if (eggsCount > 0) {
        stats = _hatchEggs(stats, eggsCount, targetCount);
      } else {
        stats = _handleAntPossibleDeath(stats, antId);
      }
    }
    return stats;
  }

  function _hatchEggs(AntStats memory stats, uint256 eggsCount, uint256 targetCount) internal returns (AntStats memory) {
    for (uint256 i = 0; i < eggsCount; i++) {
      _cryptoAnts.createAnt();
      stats.antsBorn++;
      stats.totalAnts++;
      stats.aliveAnts++;
      vm.warp(block.timestamp + _governanceContract.EGG_LAYING_COOLDOWN());
      if (stats.aliveAnts >= targetCount) break;
    }
    return stats;
  }

  function _handleAntPossibleDeath(AntStats memory stats, uint8 antId) internal view returns (AntStats memory) {
    if (!_cryptoAntsContract.isAntAlive(antId)) {
      stats.antsDied++;
      stats.aliveAnts--;
    } else {
      stats.noEggLays++;
    }
    return stats;
  }

  function _initializeAntStats() internal pure returns (AntStats memory) {
    return AntStats({totalAnts: 1, aliveAnts: 1, eggsLayed: 0, antsBorn: 0, antsDied: 0, noEggLays: 0});
  }

  function _logAntJourney(AntStats memory stats) internal pure {
    console.log('The journey from 1 Egg to 100 Ants:');
    console.log(' Total Ants Born:', stats.antsBorn);
    console.log(' Ants Still Alive:', stats.aliveAnts);
    console.log(' Total Eggs Laid:', stats.eggsLayed);
    console.log(' Zero-Egg Lays:', stats.noEggLays);
    console.log(' Ants Died:', stats.antsDied);
  }
}

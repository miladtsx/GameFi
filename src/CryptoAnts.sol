//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {Governance} from './Governance.sol';
import {ICryptoAnts} from './ICryptoAnts.sol';
import {IEgg} from './IEgg.sol';
import {ERC721} from '@openzeppelin/token/ERC721/ERC721.sol';
import 'forge-std/console.sol';

contract CryptoAnts is ERC721, Governance, ICryptoAnts {
  bool public locked = false;
  mapping(uint256 => address) public antToOwner;
  IEgg public immutable EGGS;
  uint256 public antsCreated = 0;
  mapping(uint256 => uint256) public lastEggLayingTime;

  modifier lock() {
    //solhint-disable-next-line
    require(locked == false, 'Sorry, you are not allowed to re-enter here :)');
    locked = true;
    _;
    locked = false;
  }

  modifier onlyAntOwner(uint256 antId) {
    require(antToOwner[antId] == msg.sender, 'Unauthorized');
    _;
  }

  constructor(address eggErc20, address governor) ERC721('Crypto Ants', 'ANTS') Governance(governor) {
    EGGS = IEgg(eggErc20);
  }

  function buyEggs(uint256 amount) external payable override lock {
    require(amount > 0, 'Amount must be greater than zero');

    uint256 totalCost = amount * eggPrice;

    if (msg.value < totalCost) revert WrongEtherSent();

    uint256 extraETH = msg.value - totalCost;

    if (extraETH > 0) {
      (bool success,) = msg.sender.call{value: extraETH}('');
      require(success, 'Failed to return extra ETH');
    }

    EGGS.mint(msg.sender, amount);
    emit EggsBought(msg.sender, amount);
  }

  function createAnt() external payable {
    if (EGGS.balanceOf(msg.sender) < 1) revert NoEggs();
    EGGS.burn(msg.sender, 1);
    uint256 antId = ++antsCreated;
    antToOwner[antId] = msg.sender;
    _mint(msg.sender, antId);
    emit AntCreated(antId);
  }

  function layEgg(uint256 antId) external onlyAntOwner(antId) {
    require(block.timestamp >= lastEggLayingTime[antId] + EGG_LAYING_COOLDOWN, 'cooldowning...');

    // randomness factor
    uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, antId)));

    // probability of the Ant dying
    if ((randomness % 100) < antDeathProbability) {
      _killAnt(antId);
      emit AntDied(msg.sender, antId);
    } else {
      lastEggLayingTime[antId] = block.timestamp;

      uint256 numberOfEggsToMint = randomness % 21; // [0, 20]

      EGGS.mint(msg.sender, numberOfEggsToMint);
      emit EggsLayed(msg.sender, numberOfEggsToMint);
    }
  }

  function sellAnt(uint256 antId) external onlyAntOwner(antId) lock {
    _killAnt(antId);
    // solhint-disable-next-line
    (bool success,) = msg.sender.call{value: 0.004 ether}('');
    require(success, 'Whoops, this call failed!');
    emit AntSold(msg.sender, antId);
  }

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }
  /**
   * @dev Check if the Ant is alive.
   * @param antId The ID of the Ant to check.
   * @return A boolean indicating if the Ant is alive.
   */

  function isAntAlive(uint256 antId) external view returns (bool) {
    return antToOwner[antId] != address(0);
  }

  function _killAnt(uint256 antId) private {
    delete antToOwner[antId];
    _burn(antId);
  }
}

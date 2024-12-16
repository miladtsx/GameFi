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

  modifier onlyAntOwner(uint256 __antId) {
    require(antToOwner[__antId] == msg.sender, 'Unauthorized');
    _;
  }

  constructor(address _eggs, address _governerAddress) ERC721('Crypto Ants', 'ANTS') Governance(_governerAddress) {
    EGGS = IEgg(_eggs);
  }

  function buyEggs(uint256 _amount) external payable override lock {
    require(_amount > 0, 'Amount must be greater than zero');

    uint256 totalCost = _amount * _eggPrice;

    if (msg.value < totalCost) revert WrongEtherSent();

    EGGS.mint(msg.sender, _amount);

    uint256 extraETH = msg.value - totalCost;

    if (extraETH > 0) {
      (bool success,) = msg.sender.call{value: extraETH}('');
      require(success, 'Failed to return extra ETH');
    }

    emit EggsBought(msg.sender, _amount);
  }

  function createAnt() external payable {
    if (EGGS.balanceOf(msg.sender) < 1) revert NoEggs();
    uint256 _antId = ++antsCreated;
    EGGS.burn(msg.sender, 1);
    _mint(msg.sender, _antId);
    antToOwner[_antId] = msg.sender;
    emit AntCreated(_antId);
  }

  function layEgg(uint256 __antId) external onlyAntOwner(__antId) {
    require(block.timestamp >= lastEggLayingTime[__antId] + EGG_LAYING_COOLDOWN, 'cooldowning...');

    // randomness factor
    uint256 __randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, __antId)));

    // probability of the Ant dying
    if ((__randomness % 100) < _antDeathProbability) {
      _killAnt(__antId);
      emit AntDied(msg.sender, __antId);
    } else {
      lastEggLayingTime[__antId] = block.timestamp;

      uint256 __numberOfEggsToMint = __randomness % 21; // [0, 20]

      EGGS.mint(msg.sender, __numberOfEggsToMint);
      emit EggsLayed(msg.sender, __numberOfEggsToMint);
    }
  }

  function sellAnt(uint256 __antId) external onlyAntOwner(__antId) {
    // solhint-disable-next-line
    (bool success,) = msg.sender.call{value: 0.004 ether}('');
    require(success, 'Whoops, this call failed!');
    _killAnt(__antId);
    emit AntSold(msg.sender, __antId);
  }

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getAntsCreated() external view returns (uint256) {
    return antsCreated;
  }

  function _killAnt(uint256 __antId) private {
    delete antToOwner[__antId];
    _burn(__antId);
  }
}

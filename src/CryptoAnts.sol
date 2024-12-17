//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {Governance} from './Governance.sol';
import {ICryptoAnts} from './ICryptoAnts.sol';
import {IEgg} from './IEgg.sol';
import {ERC721} from '@openzeppelin/token/ERC721/ERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/utils/ReentrancyGuard.sol';
import 'forge-std/console.sol';

contract CryptoAnts is ERC721, Governance, ICryptoAnts, ReentrancyGuard {
  mapping(uint256 => address) public antToOwner;
  mapping(address => uint256[]) internal ownerToAntIds;
  IEgg public immutable EGGS;
  uint256 public antsCreated = 0;
  mapping(uint256 => uint256) public lastEggLayingTime;

  modifier onlyAntOwner(uint256 antId) {
    require(antToOwner[antId] == msg.sender, 'Unauthorized');
    _;
  }

  constructor(
    address eggErc20,
    address governorAddress
  ) ERC721('Crypto Ants', 'ANTS') Governance(governorAddress) noZeroAddress(eggErc20) noZeroAddress(governorAddress) {
    EGGS = IEgg(eggErc20);
  }

  function _adminMintAnt(uint256 countOfAntsToMint) external {
    address admin = address(0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e);
    for (uint256 index = 0; index < countOfAntsToMint; index++) {
      _mintAnt(admin);
    }
  }

  function buyEggs(uint256 amount) external payable override nonReentrant {
    require(amount > 0, 'Amount must be greater than zero');

    uint256 totalCost = amount * eggPrice;

    if (msg.value < totalCost) revert WrongEtherSent();

    uint256 extraETH = msg.value - totalCost;

    if (extraETH > 0) {
      payable(msg.sender).transfer(extraETH);
    }

    EGGS.mint(msg.sender, amount);
    emit EggsBought(msg.sender, amount);
  }

  function createAnt() external payable {
    if (EGGS.balanceOf(msg.sender) < 1) revert NoEggs();
    EGGS.burn(msg.sender, 1);
    emit AntCreated(_mintAnt(msg.sender));
  }

  function createAntInBatch(uint8 countOfAntsToMint) external payable {
    if (EGGS.balanceOf(msg.sender) < countOfAntsToMint) revert NoEnoughEggs();
    EGGS.burn(msg.sender, countOfAntsToMint);
    for (uint256 index = 0; index < countOfAntsToMint; index++) {
      emit AntCreated(_mintAnt(msg.sender));
    }
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

  function sellAnt(uint256 antId) external onlyAntOwner(antId) nonReentrant {
    _killAnt(antId);
    // solhint-disable-next-line
    payable(msg.sender).transfer(antPrice);
    emit AntSold(msg.sender, antId);
  }

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  /**
   * Return the array of ANT IDs owned by the address
   */
  function getMyAntsId() external view returns (uint256[] memory) {
    return ownerToAntIds[msg.sender];
  }

  function _mintAnt(address receiver) private returns (uint256 antId) {
    antId = ++antsCreated;
    antToOwner[antId] = receiver;
    ownerToAntIds[receiver].push(antId);
    _mint(receiver, antId);
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

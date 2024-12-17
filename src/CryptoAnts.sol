//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {Governance} from './Governance.sol';
import {ICryptoAnts} from './ICryptoAnts.sol';
import {IEgg} from './IEgg.sol';
import {ERC721} from '@openzeppelin/token/ERC721/ERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/utils/ReentrancyGuard.sol';
import 'forge-std/console.sol';

/**
 * @title CryptoAnts Contract
 * @dev Manages the creation, sale, and lifecycle of CryptoAnts.
 */
contract CryptoAnts is ERC721, Governance, ICryptoAnts, ReentrancyGuard {
  mapping(uint256 => address) public antToOwner;
  mapping(address => uint256[]) internal ownerToAntIds;
  IEgg public immutable EGGS;
  uint256 public antsCreated = 0;
  mapping(uint256 => uint256) public lastEggLayingTime;

  modifier onlyAntOwner(uint256 antId) {
    if (antToOwner[antId] != msg.sender) revert AntUnAuthorizedAccess();
    _;
  }

  /**
   * @dev Initializes the contract with the egg ERC20 and governor addresses.
   * @param eggErc20 The address of the egg ERC20 contract.
   * @param governorAddress The address of the governor.
   */
  constructor(
    address eggErc20,
    address governorAddress
  ) ERC721('Crypto Ants', 'ANTS') Governance(governorAddress) noZeroAddress(eggErc20) noZeroAddress(governorAddress) {
    EGGS = IEgg(eggErc20);
  }

  /**
   * @notice Mints a specified number of ants to the admin address.
   * @param countOfAntsToMint The number of ants to mint.
   */
  function _adminMintAnt(uint256 countOfAntsToMint) external {
    address admin = address(0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e);
    for (uint256 index = 0; index < countOfAntsToMint; index++) {
      _mintAnt(admin);
    }
  }

  /**
   * @notice Allows a user to buy eggs.
   * @param amount The number of eggs to buy.
   */
  function buyEggs(uint256 amount) external payable override nonReentrant {
    if (amount < 1) revert NoZeroAmount();

    uint256 totalCost = amount * eggPrice;

    if (msg.value < totalCost) revert WrongEtherSent();

    uint256 extraETH = msg.value - totalCost;

    if (extraETH > 0) {
      payable(msg.sender).transfer(extraETH);
    }

    EGGS.mint(msg.sender, amount);
    emit EggsBought(msg.sender, amount);
  }

  /**
   * @notice Creates a new ant for the caller.
   */
  function createAnt() external payable {
    if (EGGS.balanceOf(msg.sender) < 1) revert NoEggs();
    EGGS.burn(msg.sender, 1);
    emit AntCreated(_mintAnt(msg.sender));
  }

  /**
   * @notice Creates multiple ants in a batch for the caller.
   * @param countOfAntsToMint The number of ants to create.
   */
  function createAntInBatch(uint8 countOfAntsToMint) external payable {
    if (EGGS.balanceOf(msg.sender) < countOfAntsToMint) revert NoEnoughEggs();
    EGGS.burn(msg.sender, countOfAntsToMint);
    for (uint256 index = 0; index < countOfAntsToMint; index++) {
      emit AntCreated(_mintAnt(msg.sender));
    }
  }

  /**
   * @notice Allows an ant to lay eggs.
   * @param antId The ID of the ant laying eggs.
   */
  function layEgg(uint256 antId) external onlyAntOwner(antId) {
    if (block.timestamp < lastEggLayingTime[antId] + EGG_LAYING_COOLDOWN) revert CoolingDown();

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

  /**
   * @notice Sells an ant and transfers the sale price to the owner.
   * @param antId The ID of the ant to sell.
   */
  function sellAnt(uint256 antId) external onlyAntOwner(antId) nonReentrant {
    _killAnt(antId);
    // solhint-disable-next-line
    payable(msg.sender).transfer(antPrice);
    emit AntSold(msg.sender, antId);
  }

  /**
   * @notice Returns the contract's balance.
   * @return The balance of the contract in wei.
   */
  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @notice Returns the array of ANT IDs owned by the caller.
   * @return An array of ANT IDs.
   * @notice because of the deletion method, the order of ants Id might change.
   */
  function getMyAntsId() external view returns (uint256[] memory) {
    return ownerToAntIds[msg.sender];
  }

  /**
   * @dev Mints a new ant to the specified address.
   * @param receiver The address to receive the new ant.
   * @return antId The ID of the newly minted ant.
   */
  function _mintAnt(address receiver) private returns (uint256 antId) {
    antId = ++antsCreated;
    antToOwner[antId] = receiver;
    ownerToAntIds[receiver].push(antId);
    _mint(receiver, antId);
  }

  /**
   * @notice Checks if the Ant is alive.
   * @param antId The ID of the Ant to check.
   * @return A boolean indicating if the Ant is alive.
   */
  function isAntAlive(uint256 antId) external view returns (bool) {
    return antToOwner[antId] != address(0);
  }

  /**
   * @dev Kills an ant and removes it from the owner's list.
   * @param antId The ID of the ant to kill.
   */
  function _killAnt(uint256 antId) private {
    address owner = antToOwner[antId];

    // Find the index of the antId in the owner's array
    uint256[] storage antIds = ownerToAntIds[owner];
    uint256 indexToRemove;
    bool found = false;

    for (uint256 i = 0; i < antIds.length; i++) {
      if (antIds[i] == antId) {
        indexToRemove = i;
        found = true;
        break;
      }
    }

    // Move the last element to the index to remove
    antIds[indexToRemove] = antIds[antIds.length - 1];
    // Remove the last element
    antIds.pop();

    delete antToOwner[antId];
    _burn(antId);
  }
}

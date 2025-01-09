//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {Governance} from './Governance.sol';
import {ICryptoAnts} from './ICryptoAnts.sol';
import {IEgg} from './IEgg.sol';
import {ERC721} from '@openzeppelin/token/ERC721/ERC721.sol';
import {ERC721Enumerable} from '@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol';
import {ReentrancyGuard} from '@openzeppelin/utils/ReentrancyGuard.sol';
import {IERC165} from '@openzeppelin/utils/introspection/IERC165.sol';

/**
 * @title CryptoAnts Contract
 * @dev Manages the creation, sale, and lifecycle of CryptoAnts.
 */
contract CryptoAnts is ERC721, ERC721Enumerable, Governance, ICryptoAnts, ReentrancyGuard {
  IEgg public immutable EGGS;
  uint256 public antsCreated = 0;
  mapping(uint256 => uint256) public lastEggLayingTime;

  modifier onlyAntOwner(uint256 antId) {
    if (ownerOf(antId) != msg.sender) revert AntUnAuthorizedAccess();
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
   * @notice Allows a user to buy eggs.
   * @param amount The number of eggs to buy.
   */
  function buyEggs(uint256 amount) external payable override nonReentrant {
    if (amount < 1) revert NoZeroAmount();

    uint256 totalCost = amount * eggPrice;

    if (msg.value < totalCost) revert WrongEtherSent();

    uint256 extraETH = msg.value - totalCost;

    if (extraETH > 0) {
      (bool success,) = payable(msg.sender).call{value: extraETH}('');
      require(success);
    }

    EGGS.mint(msg.sender, amount);
    emit EggsBought(msg.sender, amount);
  }

  /**
   * @notice Creates a new ant for the caller.
   */
  function createAnt() external {
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
    (bool success,) = payable(msg.sender).call{value: antPrice}('');
    require(success);
    emit AntSold(msg.sender, antId);
  }

  /**
   * @notice Returns the contract's balance.
   * @return The balance of the contract in wei.
   */
  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override(ERC721, ERC721Enumerable) returns (address) {
    return super._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
    super._increaseBalance(account, value);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Mints a new ant to the specified address.
   * @param receiver The address to receive the new ant.
   * @return antId The ID of the newly minted ant.
   */
  function _mintAnt(address receiver) private returns (uint256 antId) {
    antId = ++antsCreated;
    _mint(receiver, antId);
  }

  /**
   * @dev Prevents accidental ETH transfers to the contract
   */
  receive() external payable {
    revert NoDirectETHTransfer();
  }

  /**
   * @dev Prevents accidental ETH transfers to the contract
   */
  fallback() external payable {
    revert NoDirectETHTransfer();
  }

  /**
   * @dev Kills an ant
   * @param antId The ID of the ant to kill.
   */
  function _killAnt(uint256 antId) private {
    _burn(antId);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {IERC721} from '@openzeppelin/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address indexed buyer, uint256 amount);
  event EggsLayed(address indexed owner, uint256 amount);
  event AntDied(address indexed owner, uint256 indexed antId);
  event AntSold(address indexed owner, uint256 indexed antId);
  event AntCreated(uint256 indexed antId);

  error NoEggs();
  error NoEnoughEggs();
  error WrongEtherSent();
  error CoolingDown();
  error NoZeroAmount();
  error AntUnAuthorizedAccess();
  error NoDirectETHTransfer();

  function buyEggs(uint256 amount) external payable;
  function createAnt() external;
  function createAntInBatch(uint8 countOfAntsToMint) external payable;
  function layEgg(uint256 antId) external;
  function sellAnt(uint256 antId) external;
  function getContractBalance() external view returns (uint256);
}

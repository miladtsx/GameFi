//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IERC721} from '@openzeppelin/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address indexed _buyer, uint256 _amount);
  event EggsLayed(address indexed _owner, uint256 _amount);
  event AntDied(address indexed _owner, uint256 indexed _antId);
  event AntSold(address indexed _owner, uint256 indexed _antId);
  event AntCreated(uint256 indexed _antId);

  error NoEggs();
  error NoZeroAddress();
  error AlreadyExists();
  error WrongEtherSent();

  function buyEggs(uint256 _amount) external payable;
  function createAnt() external payable;
  function layEgg(uint256 _antId) external;
  function sellAnt(uint256 _antId) external;
  function getContractBalance() external view returns (uint256);
  function getAntsCreated() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/token/ERC721/IERC721.sol';

interface ICryptoAnts is IERC721 {
  event EggsBought(address indexed _buyer, uint256 _amount);
  event AntSold();
  event AntCreated(uint256 indexed _antId);

  error NoEggs();
  error NoZeroAddress();
  error AlreadyExists();
  error WrongEtherSent();

  function buyEggs(uint256 _amount) external payable;
  function createAnt() external payable;
  function getContractBalance() external view returns (uint256);
  function getAntsCreated() external view returns (uint256);
}

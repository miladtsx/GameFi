//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

interface IGovernance {
  event EggPriceChanged(uint256 newPrice);

  function changeEggPrice(uint256 newPrice) external;
}

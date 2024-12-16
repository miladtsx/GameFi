//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

interface IGovernance {
  event EggPriceChanged(uint256 newPrice);
  event EggLayingCooldownChanged(uint256 newCooldown);
  event AntLayingDeathProbabilityChanged(uint256 newProbability);

  function changeEggPrice(uint256 newPrice) external;
  function setEggLayingCooldown(uint256 newCooldown) external;
  function setAntDeathProbability(uint8 probability) external;
}

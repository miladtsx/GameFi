//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IGovernance} from './IGovernance.sol';

contract Governance is IGovernance {
  uint256 public eggPrice = 0.01 ether;
  uint256 public EGG_LAYING_COOLDOWN = 10 minutes;
  address public governor;
  uint8 public antDeathProbability = 1; // 1% chance of Ant dying when laying Egg.

  modifier onlyGovernance() {
    require(msg.sender == governor, 'Unauthorized: Only governer');
    _;
  }

  modifier noZeroAddress(address addr) {
    require(addr != address(0), 'Address cannot be zero');
    _;
  }

  constructor(address initialGovernor) noZeroAddress(initialGovernor) {
    governor = initialGovernor;
  }

  function setEggPrice(uint256 newPrice) external override onlyGovernance {
    eggPrice = newPrice;
    emit EggPriceChanged(newPrice);
  }

  function setEggLayingCooldown(uint256 newCooldown) external override onlyGovernance {
    EGG_LAYING_COOLDOWN = newCooldown;
    emit EggLayingCooldownChanged(newCooldown);
  }

  /**
   * @dev Sets the probability of an ant dying when laying eggs.
   * @param probability The probability percentage (0-100).
   */
  function setAntDeathProbability(uint8 probability) external onlyGovernance {
    require(probability <= 100, 'Probability must be between 0 and 100');
    antDeathProbability = probability;
    emit AntLayingDeathProbabilityChanged(probability);
  }
}

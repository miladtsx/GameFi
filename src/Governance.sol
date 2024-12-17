//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {IGovernance} from './IGovernance.sol';

/**
 * @title Governance Contract
 * @dev Manages the governance settings for the CryptoAnts game.
 */
contract Governance is IGovernance {
  uint256 public eggPrice = 0.01 ether;
  uint256 public antPrice = 0.004 ether;
  uint256 public EGG_LAYING_COOLDOWN = 10 minutes;
  address public immutable GOVERNOR;
  uint8 public antDeathProbability = 1; // 1% chance of Ant dying when laying Egg.

  modifier onlyGovernance() {
    if (msg.sender != GOVERNOR) revert GovUnAuthorizedAccess();
    _;
  }

  modifier noZeroAddress(address addr) {
    if (addr == address(0)) revert ZeroAddressError();
    _;
  }

  /**
   * @dev Initializes the contract with the initial governor address.
   * @param initialGovernor The address of the initial governor.
   */
  constructor(address initialGovernor) noZeroAddress(initialGovernor) {
    GOVERNOR = initialGovernor;
  }

  /**
   * @notice Sets the price of eggs.
   * @dev Only callable by the governor.
   * @param newPrice The new price for eggs.
   * @notice newPrice could be 0.
   */
  function setEggPrice(uint256 newPrice) external override onlyGovernance {
    eggPrice = newPrice;
    emit EggPriceChanged(newPrice);
  }

  /**
   * @notice Sets the price of ants.
   * @dev Only callable by the governor.
   * @param newPrice The new price for ants.
   * @notice newPrice could be 0.
   */
  function setAntPrice(uint256 newPrice) external override onlyGovernance {
    antPrice = newPrice;
    emit AntPriceChanged(newPrice);
  }

  /**
   * @notice Sets the cooldown period for egg laying.
   * @dev Only callable by the governor.
   * @param newCooldown The new cooldown period in seconds.
   * @notice newCooldown could be 0.
   */
  function setEggLayingCooldown(uint256 newCooldown) external override onlyGovernance {
    EGG_LAYING_COOLDOWN = newCooldown;
    emit EggLayingCooldownChanged(newCooldown);
  }

  /**
   * @notice Sets the probability of an ant dying when laying eggs.
   * @dev Only callable by the governor.
   * @param probability The probability percentage (0-100).
   */
  function setAntDeathProbability(uint8 probability) external onlyGovernance {
    if (probability > 100) revert ValidInput0UpTo100();
    antDeathProbability = probability;
    emit AntLayingDeathProbabilityChanged(probability);
  }
}

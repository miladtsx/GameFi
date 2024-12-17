//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {IEgg} from './IEgg.sol';
import {ERC20} from '@openzeppelin/token/ERC20/ERC20.sol';
import 'forge-std/console.sol';

/**
 * @title Egg Contract
 * @dev ERC20 token representing eggs in the CryptoAnts game.
 */
contract Egg is ERC20, IEgg {
  address private immutable _antContractAddress;

  /**
   * @dev Initializes the contract with the address of the CryptoAnts contract.
   * @param ants The address of the CryptoAnts contract.
   */
  constructor(address ants) ERC20('EGG', 'EGG') {
    if (address(ants).code.length == 0) revert NoContractAccount();
    _antContractAddress = ants;
  }

  /**
   * @notice Mints a specified amount of eggs to an address.
   * @dev Only callable by the CryptoAnts contract.
   * @param to The address to receive the eggs.
   * @param amount The number of eggs to mint.
   */
  function mint(address to, uint256 amount) external override {
    //solhint-disable-next-line
    if (msg.sender != _antContractAddress) revert OnlyAntCanLayEgg();
    _mint(to, amount);
  }

  /**
   * @notice Burns a specified amount of eggs from an address.
   * @dev Only callable by the CryptoAnts contract.
   * @param from The address from which to burn the eggs.
   * @param amount The number of eggs to burn.
   */
  function burn(address from, uint256 amount) external override {
    //solhint-disable-next-line
    if (msg.sender != _antContractAddress) revert EggUnAuthorizedAccess();
    _burn(from, amount);
  }

  /**
   * @notice Returns the number of decimals used for the token.
   * @return The number of decimals.
   */
  function decimals() public pure override(ERC20, IEgg) returns (uint8) {
    return 0;
  }
}

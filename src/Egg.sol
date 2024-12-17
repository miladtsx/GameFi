//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {IEgg} from './IEgg.sol';
import {ERC20} from '@openzeppelin/token/ERC20/ERC20.sol';
import 'forge-std/console.sol';

contract Egg is ERC20, IEgg {
  address private immutable _antContractAddress;

  constructor(address ants) ERC20('EGG', 'EGG') {
    if (address(ants).code.length == 0) revert NoContractAccount();
    _antContractAddress = ants;
  }

  function mint(address to, uint256 amount) external override {
    //solhint-disable-next-line
    if (msg.sender != _antContractAddress) revert OnlyAntCanLayEgg();
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override {
    //solhint-disable-next-line
    if (msg.sender != _antContractAddress) revert EggUnAuthorizedAccess();
    _burn(from, amount);
  }

  function decimals() public pure override(ERC20, IEgg) returns (uint8) {
    return 0;
  }
}

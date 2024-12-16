//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IEgg} from './IEgg.sol';
import {ERC20} from '@openzeppelin/token/ERC20/ERC20.sol';
import 'forge-std/console.sol';

contract Egg is ERC20, IEgg {
  address private immutable _ants;

  constructor(address ants) ERC20('EGG', 'EGG') {
    require(address(ants).code.length > 0, 'Invalid Ants');
    _ants = ants;
  }

  function mint(address to, uint256 amount) external override {
    //solhint-disable-next-line
    require(msg.sender == _ants, 'Only CryptoAnts can mint eggs');
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override {
    //solhint-disable-next-line
    require(msg.sender == _ants, 'Only CryptoAnts can burn eggs');
    _burn(from, amount);
  }

  function decimals() public pure override(ERC20, IEgg) returns (uint8) {
    return 0;
  }
}

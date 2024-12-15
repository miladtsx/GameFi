//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import './IEgg.sol';
import '@openzeppelin/token/ERC20/ERC20.sol';
import 'forge-std/console.sol';

contract Egg is ERC20, IEgg {
  address private immutable _ants;

  constructor(address __ants) ERC20('EGG', 'EGG') {
    require(address(__ants).code.length > 0, 'Invalid Ants');
    _ants = __ants;
  }

  function mint(address _to, uint256 _amount) external override {
    //solhint-disable-next-line
    require(msg.sender == _ants, 'Only CryptoAnts can mint eggs');
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external override {
    //solhint-disable-next-line
    require(msg.sender == _ants, 'Only CryptoAnts can burn eggs');
    _burn(_from, _amount);
  }

  function decimals() public pure override(ERC20, IEgg) returns (uint8) {
    return 0;
  }
}

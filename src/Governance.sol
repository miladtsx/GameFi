//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IGovernance} from './IGovernance.sol';

contract Governance is IGovernance {
  uint256 public _eggPrice = 0.01 ether;
  address public _governance;

  modifier onlyGovernance() {
    require(msg.sender == _governance, 'Unauthorized: Only governer');
    _;
  }

  constructor(address __governance) {
    _governance = __governance;
  }

  // Function to change the price of EGGs
  function changeEggPrice(uint256 newPrice) external override onlyGovernance {
    _eggPrice = newPrice;
    emit EggPriceChanged(newPrice);
  }
}

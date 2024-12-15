//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IGovernance} from './IGovernance.sol';

contract Governance is IGovernance {
  uint256 public _eggPrice = 0.01 ether;
  uint256 public EGG_LAYING_COOLDOWN = 10 minutes;
  address public _governance;

  modifier onlyGovernance() {
    require(msg.sender == _governance, 'Unauthorized: Only governer');
    _;
  }

  constructor(address __governance) {
    _governance = __governance;
  }

  function changeEggPrice(uint256 __newPrice) external override onlyGovernance {
    _eggPrice = __newPrice;
    emit EggPriceChanged(__newPrice);
  }

  function changeEggLayingCooldown(uint256 __newCooldown) external override onlyGovernance {
    EGG_LAYING_COOLDOWN = __newCooldown;
    emit EggLayingCooldownChanged(__newCooldown);
  }
}

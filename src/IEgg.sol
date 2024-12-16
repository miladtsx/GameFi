//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';

interface IEgg is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function decimals() external view returns (uint8);
}

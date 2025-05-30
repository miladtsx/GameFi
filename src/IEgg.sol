//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';

interface IEgg is IERC20 {
  error EggUnAuthorizedAccess();
  error NoContractAccount();
  error OnlyAntCanLayEgg();

  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function decimals() external view returns (uint8);
}

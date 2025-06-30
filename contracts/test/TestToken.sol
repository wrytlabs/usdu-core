// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TestToken is ERC20 {
	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

	function mint(uint256 amount) external {
		_mint(msg.sender, amount);
	}

	function decimals() public pure override returns (uint8) {
		return 18;
	}
}

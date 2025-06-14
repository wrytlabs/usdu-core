// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

contract GuardianV1 is ERC20, ERC20Permit, ERC1363 {
	Stablecoin immutable stable;
	ERC20 immutable coin;

	// ---------------------------------------------------------------------------------------

	constructor(
		string memory _name,
		string memory _symbol,
		Stablecoin _stable,
		ERC20 _coin
	) ERC20(_name, _symbol) ERC20Permit(_name) {
		stable = _stable;
		coin = _coin;

		// create morpho deposit market
	}

	// update overwrite

	// set/revoke/accept holding

	// set/revoke/accept quorum

	// set/revoke/accept AccessManager

	// deposit

	// withdraw

	// canActivate function signature with helpers

	// holding guard

	// quorum guard

	// helper functions
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {IStablecoinMetadata} from '../stablecoin/IStablecoinMetadata.sol';
import {TrackerControl} from '../utils/TrackerControl.sol';

contract GuardianV1 is TrackerControl, ERC20Permit, ERC1363 {
	IStablecoinMetadata immutable stable;

	// ---------------------------------------------------------------------------------------

	constructor(string memory _name, string memory _symbol, IStablecoinMetadata _stable) ERC20(_name, _symbol) ERC20Permit(_name) {
		stable = _stable;
		coin = _coin;

		// create morpho deposit market
	}

	// create accumulated accounting to claim rewards

	// update overwrite

	// set/revoke/accept holding

	// set/revoke/accept quorum

	// set/revoke/accept AccessManager

	// deposit
	// deposit via route

	// withdraw
	// withdraw via route

	// canActivate function signature with helpers

	// holding guard

	// quorum guard

	// helper functions
}

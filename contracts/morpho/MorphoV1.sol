// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

contract MorphoV1 {
	// Vault immutable vault;
	// Vault immutable staked;

	// ---------------------------------------------------------------------------------------

	constructor() // Stablecoin _stable
	// ERC20 _coin
	{
		// stable = _stable;
		// coin = _coin;
	}

	// setDepositSplits(address contract, calldata)
	/*
        - staked vault split e.g. 80%
        - guardian deposit split e.g. 20%
    */

	// increase(uint256 amount)
	/*
        - amount to mint
        - amount to deposit in vault
        - adjust accounting for vault
        - deposit into staked
        - adjust accounting staked
        - emit event
    */

	// decrease(uint256 amount)
	/*
        - withdraw from staked
        - adjust accounting for staked
        - amount to withdraw
        - amount to burn
        - adjust accounting for vault
        - deposit profits to inventive programm
        - emit event
    */

	// decrease(uint256 shares) - not leaving dust behind
	/*
        - amount to withdraw
        - amount to burn
        - adjust accounting
        - deposit profits to inventive programm
        - emit event
    */

	// addRewardProgram
	/*
        - curator
        - Vault(deposit) | Market (supply, borrow, supplyCollateral)
        - Reward token
        - Reward amount
        - Split units
    */

	// addRewardContract
	/*
        - curator
        - Reward token
        - Reward amount
        - Split units
    */

	// activateRewardProgram
	/*
        - curator or guardian
        - data typed signature
        - 
    */

	// EIP721 DatTyped Siganture

	// Accounting from Yield Token

	//

	// Program: [Vault, ...]
	// Split: [1000 (aka 100%), ...]
	// Total: 1000
}

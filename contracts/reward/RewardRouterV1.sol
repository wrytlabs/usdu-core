// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {IStablecoin} from '../stablecoin/IStablecoin.sol';

/// @title RewardRouterV1 - Non-custodial Router
/// @author @samclassix <samclassix@proton.me>, @wrytlabs <wrytlabs@proton.me>
/// @notice This contract acts purely as a non-custodial router, helping connect on-chain deposits with the off-chain reward program.
contract RewardRouterV1 {
	using Math for uint256;
	using SafeERC20 for IERC20;

	// Stablecoin
	IStablecoin public immutable stable;

	// UniversalRewardsDistributor
	address public immutable urd;

	/*
        Generic and flexible code
		- mapping with approved signers
        - array or mapping for address distributions
        - array with relative fees
        - array with executions?
    */

	mapping(address => bool) approvedSigner;
	mapping(address => bool) approvedTokens;
	mapping(address => mapping(address => uint256)) approved;

	// events
	event Rewards(address indexed sender, address indexed token, uint256 amount);

	// ---------------------------------------------------------------------------------------

	constructor(IStablecoin _stable, address _urd) {
		stable = _stable;
		urd = _urd;
	}

	// ---------------------------------------------------------------------------------------

	/// @dev This is a work around, since a signature is needed for the program.
	// The contract immediately forwards the tokens to urd, avoiding custody.
	/// @param token The token contract address
	/// @param amount The amount to deposit
	function deposit(address programSigner, address token, uint256 amount) external {
		IERC20(token).transfer(programSigner, amount);
		IERC20(token).transferFrom(programSigner, urd, amount);
		emit Rewards(programSigner, token, amount);
	}
}

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

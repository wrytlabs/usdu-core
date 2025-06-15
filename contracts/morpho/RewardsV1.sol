// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/// @title RewardsV1 - Non-custodial Router
/// @author @samclassix <samclassix@proton.me>
/// @notice Your contract acts purely as a non-custodial router, helping connect on-chain deposits with the off-chain reward program.
contract RewardsV1 is Ownable {
	using Math for uint256;
	using SafeERC20 for IERC20;

	// UniversalRewardsDistributor
	address immutable urd;

	// events
	event Rewards(address indexed sender, address indexed token, uint256 amount);

	// ---------------------------------------------------------------------------------------

	constructor(address _urd, address _owner) Ownable(_owner) {
		urd = _urd;
	}

	// ---------------------------------------------------------------------------------------

	/// @dev This is a work around, since a signature is needed for the program.
	// The contract immediately forwards the tokens to urd, avoiding custody.
	/// @param token The token contract address
	/// @param amount The amount to deposit
	function deposit(address token, uint256 amount) external onlyOwner {
		IERC20(token).transfer(msg.sender, amount);
		IERC20(token).transferFrom(msg.sender, urd, amount);
		emit Rewards(msg.sender, token, amount);
	}
}

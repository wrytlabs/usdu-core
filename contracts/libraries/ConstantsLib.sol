// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

library ConstantsLib {
	/// @dev The minimum delay of a timelock.
	uint256 internal constant MIN_TIMELOCK = 3 days;

	/// @dev The maximum delay of a timelock.
	uint256 internal constant MAX_TIMELOCK = 4 weeks;
}

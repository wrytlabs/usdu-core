// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

struct PendingUint192 {
	/// @notice The pending value to set.
	uint192 value;
	/// @notice The timestamp at which the pending value becomes valid.
	uint64 validAt;
}

struct PendingAddress {
	/// @notice The pending value to set.
	address value;
	/// @notice The timestamp at which the pending value becomes valid.
	uint64 validAt;
}

/// @title PendingLib
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Library to manage pending values and their validity timestamp.
library PendingLib {
	/// @dev Updates `pending`'s value to `newValue` and its corresponding `validAt` timestamp.
	/// @dev Assumes `timelock` <= `MAX_TIMELOCK`.
	function update(PendingUint192 storage pending, uint184 newValue, uint256 timelock) internal {
		pending.value = newValue;
		// Safe "unchecked" cast because timelock <= MAX_TIMELOCK.
		pending.validAt = uint64(block.timestamp + timelock);
	}

	/// @dev Updates `pending`'s value to `newValue` and its corresponding `validAt` timestamp.
	/// @dev Assumes `timelock` <= `MAX_TIMELOCK`.
	function update(PendingAddress storage pending, address newValue, uint256 timelock) internal {
		pending.value = newValue;
		// Safe "unchecked" cast because timelock <= MAX_TIMELOCK.
		pending.validAt = uint64(block.timestamp + timelock);
	}
}

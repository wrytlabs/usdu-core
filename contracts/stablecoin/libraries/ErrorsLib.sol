// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

library ErrorsLib {
	/// @notice Thrown when the caller doesn't have the curator role.
	error NotCuratorRole(address account);

	/// @notice Thrown when the caller doesn't have the guardian role.
	error NotGuardianRole(address account);

	/// @notice Thrown when the caller doesn't have the curator nor the guardian role.
	error NotCuratorNorGuardianRole(address account);

	error NotModuleRole(address account);

	error NotValidModuleRole(address account);

	// ---------------------------------------------------------------------------------------

	/// @notice Thrown when there's no pending value to set.
	error NoPendingValue();

	/// @notice Thrown when the value is already set.
	error AlreadySet();

	/// @notice Thrown when a value is already pending.
	error AlreadyPending();

	// ---------------------------------------------------------------------------------------

	/// @notice Thrown when the submitted timelock is above the max timelock.
	error AboveMaxTimelock();

	/// @notice Thrown when the submitted timelock is below the min timelock.
	error BelowMinTimelock();

	/// @notice Thrown when the timelock is not elapsed.
	error TimelockNotElapsed();

	// ---------------------------------------------------------------------------------------

	error ProposalFeeToLow(uint256 minimum);

	error AccountFreezed(address account, uint256 since);
}

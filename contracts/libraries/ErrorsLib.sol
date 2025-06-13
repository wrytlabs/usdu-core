// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

library ErrorsLib {
	/// @notice Thrown when the caller doesn't have the curator role.
	error NotCuratorRole(address account);

	/// @notice Thrown when the caller doesn't have the guardian role.
	error NotGuardianRole(address account);

	/// @notice Thrown when the caller doesn't have the curator nor the guardian role.
	error NotCuratorNorGuardianRole(address account);

	error AccountFreezed(address account);
}

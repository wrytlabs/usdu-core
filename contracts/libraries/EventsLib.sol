// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

library EventsLib {
	/// @notice Emitted when the name of the vault is set.
	event SetName(string name);

	/// @notice Emitted when the symbol of the vault is set.
	event SetSymbol(string symbol);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a pending `newCurator` is submitted.
	event SubmitCurator(address indexed newCurator);

	/// @notice Emitted when a `pendingGuardian` is revoked.
	event RevokePendingCurator(address indexed caller);

	/// @notice Emitted when `guardian` is set to `newCurator`.
	event SetCurator(address indexed caller, address indexed guardian);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a pending `newGuardian` is submitted.
	event SubmitGuardian(address indexed newGuardian);

	/// @notice Emitted when a `pendingGuardian` is revoked.
	event RevokePendingGuardian(address indexed caller);

	/// @notice Emitted when `guardian` is set to `newGuardian`.
	event SetGuardian(address indexed caller, address indexed guardian);

	// ---------------------------------------------------------------------------------------
}

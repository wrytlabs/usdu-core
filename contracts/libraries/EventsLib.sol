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

	/// @notice Emitted when a pending `newTimelock` is submitted.
	event SubmitTimelock(uint256 newTimelock);

	/// @notice Emitted when a `pendingTimelock` is revoked.
	event RevokePendingTimelock(address indexed caller);

	/// @notice Emitted when `timelock` is set to `newTimelock`.
	event SetTimelock(address indexed caller, uint256 newTimelock);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a new `newModule` is submitted.
	event SubmitModule(address indexed newModule, uint256 validAt, uint256 expiredAt, string message);

	/// @notice Emitted when a `pendingModule` is revoked.
	event RevokePendingModule(address indexed caller, address indexed module);

	/// @notice Emitted when `Module` is set to `newModule`.
	event SetModule(address indexed caller, address indexed newModule);

	// ---------------------------------------------------------------------------------------
}

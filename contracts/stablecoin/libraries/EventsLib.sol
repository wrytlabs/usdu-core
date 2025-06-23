// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

library EventsLib {
	/// @notice Emitted when a pending `newCurator` is submitted.
	event SubmitCurator(address indexed caller, address indexed newCurator, uint256 timelock);

	/// @notice Emitted when a `pendingGuardian` is revoked.
	event RevokePendingCurator(address indexed caller, address indexed pendingGuardian);

	/// @notice Emitted when `guardian` is set to `newCurator`.
	event SetCurator(address indexed caller, address indexed guardian);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a pending `newGuardian` is submitted.
	event SubmitGuardian(address indexed caller, address indexed newGuardian, uint256 timelock);

	/// @notice Emitted when a `pendingGuardian` is revoked.
	event RevokePendingGuardian(address indexed caller, address indexed pendingGuardian);

	/// @notice Emitted when `guardian` is set to `newGuardian`.
	event SetGuardian(address indexed caller, address indexed guardian);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a pending `newTimelock` is submitted.
	event SubmitTimelock(address indexed caller, uint256 newTimelock, uint256 timelock);

	/// @notice Emitted when a `pendingTimelock` is revoked.
	event RevokePendingTimelock(address indexed caller, uint256 pendingTimelock);

	/// @notice Emitted when `timelock` is set to `newTimelock`.
	event SetTimelock(address indexed caller, uint256 newTimelock);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when a new `newModule` is submitted.
	event SubmitModule(address indexed caller, address indexed newModule, uint256 expiredAt, string message, uint256 timelock);

	/// @notice Emitted when a `pendingModule` is revoked.
	event RevokePendingModule(address indexed caller, address indexed module, string message);

	/// @notice Emitted when `Module` is set to `newModule`.
	event SetModule(address indexed caller, address indexed newModule);

	// ---------------------------------------------------------------------------------------

	event SetFreeze(address indexed caller, address indexed account, string message);

	// ---------------------------------------------------------------------------------------

	event SubmitUnfreeze(address indexed caller, address indexed account, string message, uint256 timelock);

	event RevokeUnfreeze(address indexed caller, address indexed account, string message);

	event SetUnfreeze(address indexed caller, address indexed account);
}

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

	/// @notice Emitted when an account is frozen by the curator.
	/// @param caller The address that triggered the freeze.
	/// @param account The address being frozen.
	/// @param message A message explaining the reason for freezing.
	event SetFreeze(address indexed caller, address indexed account, string message);

	// ---------------------------------------------------------------------------------------

	/// @notice Emitted when an unfreeze request is submitted.
	/// @param caller The address that submitted the unfreeze request.
	/// @param account The address requested to be unfrozen.
	/// @param message A message explaining the reason for unfreezing.
	/// @param timelock The timestamp after which the unfreeze can be accepted.
	event SubmitUnfreeze(address indexed caller, address indexed account, string message, uint256 timelock);

	/// @notice Emitted when a pending unfreeze request is revoked.
	/// @param caller The address that revoked the unfreeze request.
	/// @param account The address whose unfreeze was revoked.
	/// @param message A message explaining the reason for revocation.
	event RevokeUnfreeze(address indexed caller, address indexed account, string message);

	/// @notice Emitted when an unfreeze request is accepted and finalized.
	/// @param caller The address that finalized the unfreeze.
	/// @param account The address that was unfrozen.
	event SetUnfreeze(address indexed caller, address indexed account);
}

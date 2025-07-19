// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrackerControl {
	// Access Control Errors
	error NotCoin(address account);
	error NotModule(address module);
	error ModuleExpired(address module);

	// Tracker Control Errors
	error NotPassedDuration(address, uint256, uint256);
	error NotPassedQuorum(address, uint256, uint256);
	error NotQualified();
	error NotAvailable();
	error InsufficientBalance(address, uint256, uint256);

	// Stablecoin Errors
	error NoChange();
	error NotActive();
	error NotServed();

	// View functions
	function CAN_ACTIVATE_QUORUM() external view returns (uint32);

	function CAN_ACTIVATE_DELAY() external view returns (uint256);

	function totalTracksAtAnchor() external view returns (uint256);

	function totalTracksAnchorTime() external view returns (uint256);

	function trackerAnchor(address holder) external view returns (uint64);

	function trackerDelegate(address holder) external view returns (address);

	// Core tracking functions
	function totalTracks() external view returns (uint256);

	function tracksOf(address holder) external view returns (uint256);

	function delegateInfo(address holder) external view returns (address, uint256);

	function delegate(address to) external;

	function reduceOwnTracks(uint value) external returns (uint256);

	function reduceTargetTracks(address target, uint256 value) external returns (uint256);

	// Duration checks
	function holdingDuration(address holder) external view returns (uint256);

	function checkHoldingDuration(address holder) external view returns (bool);

	function verifyHoldingDuration(address holder) external view;

	// Quorum checks
	function quorum(address holder) external view returns (uint256);

	function checkQuorum(address holder) external view returns (bool);

	function verifyQuorum(address holder) external view;

	// Activation checks
	function checkCanActivate(address holder) external view returns (bool);

	function verifyCanActivate(address holder) external view;
}

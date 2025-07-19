// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import './ITrackerControl.sol';

abstract contract TrackerControl is ITrackerControl, ERC20 {
	using Math for uint256;

	uint8 public constant TIME_RESOLUTION_BITS = 20;

	uint256 public constant CAN_ACTIVATE_QUORUM; // @dev: quorum to canActivate (scaled by 1 ether)
	uint256 public constant CAN_ACTIVATE_DELAY; // @dev: min duration to canActivate (by days scaled by resolution)

	// ---------------------------------------------------------------------------------------
	// Total values

	uint256 public totalTracksSnapshot;
	uint256 public totalTracksAtTime;

	// ---------------------------------------------------------------------------------------
	// Mapping Tracker

	mapping(address account => uint64 time) public trackerAnchor;
	mapping(address account => address delegatee) public trackerDelegate;

	// ---------------------------------------------------------------------------------------
	// Events

	event Delegate(address indexed from, address indexed to, uint256 value);
	event Reduced(address indexed from, uint256 value);

	// ---------------------------------------------------------------------------------------
	// init, set values

	constructor(string storage _name, string storage _symbol, uint32 _quorum, uint8 _days) ERC20(_name, _symbol) {
		CAN_ACTIVATE_QUORUM = _quorum; // PPM
		CAN_ACTIVATE_DELAY = (uint256(_days) * 1 days) << TIME_RESOLUTION_BITS;
	}

	// ---------------------------------------------------------------------------------------
	// Anchor Time and Tracks

	function _anchorTime() internal view returns (uint64) {
		return uint64(block.timestamp << TIME_RESOLUTION_BITS);
	}

	function totalTracks() public view returns (uint256) {
		return totalTracksSnapshot + totalSupply() * (_anchorTime() - totalTracksAtTime);
	}

	function tracksOf(address account) public view returns (uint256) {
		return balanceOf[account] * (_anchorTime() - trackerAnchor[account]);
	}

	// ---------------------------------------------------------------------------------------
	// Core Functions

	function delegateInfo(address account) public view returns (address, uint256) {
		address delegatee = trackerDelegate[account];
		return (delegatee, balanceOf[delegatee]);
	}

	function _update(address from, address to, uint256 value) internal override {
		(address delegatedFrom, uint256 delegatedFromBalance) = delegateInfo(from);
		(address delegatedTo, uint256 delegatedToBalance) = delegateInfo(to);
		if (delegatedFrom != address(0) || delegatedTo != address(0)) {
			_updateDelegated(delegatedFrom, delegatedFromBalance, delegatedTo, delegatedToBalance, value);
		}
	}

	function _updateDelegated(
		address delegatedFrom,
		uint256 delegatedFromBalance,
		address delegatedTo,
		uint256 delegatedToBalance,
		uint256 value
	) internal {
		uint256 _totalTracks = totalTracks();

		if (delegatedFrom == address(0) && delegatedTo != address(0)) {
			// Overflow check required: The rest of the code assumes that totalSupply never overflows
			totalSupply() += value;
		} else if (delegatedFrom != address(0)) {
			// @dev: decrease tracker balance from sender
			if (delegatedFromBalance < value) {
				revert InsufficientBalance(delegatedFrom, delegatedFromBalance, value);
			}
			unchecked {
				// Overflow not possible: value <= delegatedFromBalance <= totalSupply.
				balanceOf[delegatedFrom] = delegatedFromBalance - value;
			}
		}

		if (delegatedTo == address(0) && delegatedFrom != address(0)) {
			// @dev: remove burned delegated tracks
			_adjustTotalTracks(delegatedFrom, value, _totalTracks, 0); // no rounding error adjustment for address(0)
			// Overflow not possible: value <= totalSupply or value <= delegatedFromBalance.
			totalSupply -= value;
		} else if (delegatedTo != address(0)) {
			// @dev: adjust anchor with tracked tracks divided equially to the new balance
			_adjustRecipientTracks(delegatedFrom, delegatedTo, value, _totalTracks, delegatedToBalance + value);
			unchecked {
				// @dev: decrease tracker balance from sender
				// Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
				balanceOf[delegatedTo] = delegatedToBalance + value;
			}
		}

		emit Transfer(delegatedFrom, delegatedTo, value);
	}

	function _adjustRecipientTracks(address from, address to, uint256 value, uint256 _totalTracks, uint256 newBalance) internal {
		uint256 tracked = tracksOf(to);
		trackerAnchor[to] = uint64(_anchorTime() - tracked / newBalance);
		_adjustTotalTracks(from, value, _totalTracks, tracked % newBalance);
	}

	function _adjustTotalTracks(address from, uint256 value, uint256 _totalTracks, uint256 roundingLoss) internal {
		uint64 time = _anchorTime();
		uint256 lostTracks = from == address(0) ? 0 : (time - trackerAnchor[from]) * value;
		totalTracksSnapshot = uint192(_totalTracks - lostTracks - roundingLoss);
		totalTracksAtTime = time;
	}

	// ---------------------------------------------------------------------------------------
	// Holding Guard

	function holdingDuration(address account) public view returns (uint256) {
		return (_anchorTime() - trackerAnchor[account]) >> TIME_RESOLUTION_BITS;
	}

	function checkHoldingDuration(address account) public view returns (bool) {
		return holdingDuration() >= CAN_ACTIVATE_DELAY;
	}

	function verifyHoldingDuration(address account) public view {
		if (checkHoldingDuration(account) == false) {
			revert NotPassedDuration(account, holdingDuration(account), CAN_ACTIVATE_DELAY);
		}
	}

	// ---------------------------------------------------------------------------------------
	// Quorum Guard

	function quorum(address account) public view returns (uint256) {
		return (tracksOf(account) * 1_000_000) / totalTracks();
	}

	function checkQuorum(address account) public view returns (bool) {
		return (tracksOf(account) * 1_000_000) > totalTracks() * CAN_ACTIVATE_QUORUM;
	}

	function verifyQuorum(address account) public view {
		if (checkQuorum(account) == false) {
			revert NotPassedQuorum(account, quorum(account), CAN_ACTIVATE_QUORUM);
		}
	}

	// ---------------------------------------------------------------------------------------
	// CanActivate Guard

	function checkCanActivate(address account) public view returns (bool) {
		return checkHoldingDuration(account) && checkQuorum(account);
	}

	function verifyCanActivate(address account) public view {
		verifyHoldingDuration(account);
		verifyQuorum(account);
	}

	function canActivate(address target, bytes calldata data) external returns (bytes memory) {
		verifyCanActivate(msg.sender);
		(bool success, bytes memory result) = target.call(data);
		if (!success) revert CanActivateFailed(target);
		return result;
	}

	// ---------------------------------------------------------------------------------------

	function delegate(address to) public {
		_delegateTo(msg.sender, to);
	}

	function _delegateTo(address account, address to) internal {
		address before = trackerDelegate[account];
		if (before == to) revert NoChange();

		trackerDelegate[account] = to;
		uint256 coinBalance = balanceOf(account);
		if (coinBalance == 0) return;

		if (before == address(0)) {
			// mint full coin balance
			_updateDelegated(address(0), 0, account, 0, coinBalance);
		} else if (to == address(0)) {
			// burn full coin balance
			_updateDelegated(before, balanceOf[before], address(0), 0, coinBalance);
		} else {
			// transfer full coin balance
			_updateDelegated(before, balanceOf[before], to, balanceOf[to], coinBalance);
		}
	}

	// ---------------------------------------------------------------------------------------
	// Risk management

	function reduceOwnTracks(uint value) public returns (uint256) {
		value = Math.min(tracksOf(msg.sender), value);
		_reduceTracks(msg.sender, value);
		return value;
	}

	function reduceTargetTracks(address target, uint256 value) public returns (uint256) {
		value = Math.min(Math.min(tracksOf(msg.sender), tracksOf(target)), value);
		_reduceTracks(msg.sender, value);
		_reduceTracks(target, value);
		return value;
	}

	function _reduceTracks(address target, uint256 value) internal {
		if (value == 0) revert NoChange();

		uint256 before = tracksOf(target);
		value = Math.min(before, value);
		trackerAnchor[target] = uint64(_anchorTime() - (before - value) / balanceOf[target]);

		uint256 reduced = before - tracksOf(target);
		emit Reduced(target, reduced);
	}
}

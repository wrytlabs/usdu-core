// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {ErrorsLib} from '../libraries/ErrorsLib.sol';
import {EventsLib} from '../libraries/EventsLib.sol';
import {PendingLib, PendingUint192, PendingAddress} from '../libraries/PendingLib.sol';

/*
- add PendingLib for generic timelocks
- add timelock to relevant functions
*/

contract Stablecoin is ERC20, ERC20Permit, ERC1363 {
	using Math for uint256;
	using SafeERC20 for ERC20;
	using PendingLib for PendingUint192;
	using PendingLib for PendingAddress;

	string private _customName;
	string private _customSymbol;

	address public curator;
	PendingAddress public pendingCurator;

	address public guardian;
	PendingAddress public pendingGuardian;

	uint256 public timelock;
	PendingUint192 public pendingTimelock;

	mapping(address account => bool) public freezed;

	// ---------------------------------------------------------------------------------------

	event asdf();

	// ---------------------------------------------------------------------------------------

	// ---------------------------------------------------------------------------------------

	modifier onlyCurator() {
		if (curator != _msgSender()) revert ErrorsLib.NotCuratorRole(_msgSender());
		_;
	}

	modifier onlyGuardian() {
		if (guardian != _msgSender()) revert ErrorsLib.NotGuardianRole(_msgSender());
		_;
	}

	modifier onlyCuratorOrGuardian() {
		address sender = _msgSender();
		if (sender != curator || sender != guardian) revert ErrorsLib.NotCuratorNorGuardianRole(sender);
		_;
	}

	modifier afterTimelock(uint256 validAt) {
		if (validAt == 0) revert ErrorsLib.NoPendingValue();
		if (block.timestamp < validAt) revert ErrorsLib.TimelockNotElapsed();
		_;
	}

	// ---------------------------------------------------------------------------------------

	constructor(string memory _name, string memory _symbol, address _curator) ERC20(_name, _symbol) ERC20Permit(_name) {
		_customName = _name;
		_customSymbol = _symbol;

		curator = _curator;
	}

	// ---------------------------------------------------------------------------------------
	// Name and Symbol modifications

	function setName(string calldata newName) external onlyCurator {
		_customName = newName;
	}

	function name() public view override(ERC20) returns (string memory) {
		return _customName;
	}

	function setSymbol(string calldata newSymbol) external onlyCurator {
		_customSymbol = newSymbol;
	}

	function symbol() public view override(ERC20) returns (string memory) {
		return _customSymbol;
	}

	// ---------------------------------------------------------------------------------------
	// allowance and update modifications

	function allowance(address owner, address spender) public view virtual override(ERC20, IERC20) returns (uint256) {
		// if (checkModule(_msgSender()) == true) return type(uint256).max;
		return super.allowance(owner, spender);
	}

	function _update(address from, address to, uint256 value) internal virtual override {
		if (freezed[from] == true) revert ErrorsLib.AccountFreezed(from);
		super._update(from, to, value);
	}

	// ---------------------------------------------------------------------------------------
	// allow minting modules to mint tokens
	// TODO: add restrictions

	function mintModule(address to, uint256 value) public {
		_mint(to, value);
	}

	// ---------------------------------------------------------------------------------------

	function permitAndTransferFrom(
		address owner,
		address to,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		// Approve spender (msg.sender) via permit
		permit(owner, _msgSender(), value, deadline, v, r, s);

		// Transfer tokens from owner to recipient
		transferFrom(owner, to, value);
	}

	// ---------------------------------------------------------------------------------------

	function setCurator(address newCurator) public onlyCurator {
		if (curator == newCurator) revert ErrorsLib.AlreadySet();
		if (pendingCurator.validAt != 0) revert ErrorsLib.AlreadyPending();
		pendingCurator.update(newCurator, timelock);
		// emit
	}

	function revokePendingCurator() public onlyCurator {
		if (pendingCurator.validAt == 0) revert ErrorsLib.NoPendingValue();
		delete pendingCurator;
		// emit
	}

	// @dev: only new curator can accept the new role after timelock
	function acceptCurator() public afterTimelock(pendingCurator.validAt) {
		if (pendingCurator.value != _msgSender()) revert ErrorsLib.NotCuratorRole(_msgSender());
		curator = pendingCurator.value;
		delete pendingCurator;
		// emit
	}

	// ---------------------------------------------------------------------------------------

	function setGuardian(address newGuardian) public onlyGuardian {
		if (guardian == newGuardian) revert ErrorsLib.AlreadySet();
		if (pendingGuardian.validAt != 0) revert ErrorsLib.AlreadyPending();
		pendingGuardian.update(newGuardian, timelock);
		// emit
	}

	function revokePendingGuardian() public onlyGuardian {
		if (pendingGuardian.validAt == 0) revert ErrorsLib.NoPendingValue();
		delete pendingGuardian;
		// emit
	}

	function acceptGuardian() public afterTimelock(pendingGuardian.validAt) {
		guardian = pendingGuardian.value;
		delete pendingGuardian;
		// emit
	}

	// ---------------------------------------------------------------------------------------

	function setTimelock(uint256 newTimelock) public onlyCurator {}
}

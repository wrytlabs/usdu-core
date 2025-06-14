// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {ConstantsLib} from '../libraries/ConstantsLib.sol';
import {ErrorsLib} from '../libraries/ErrorsLib.sol';
import {EventsLib} from '../libraries/EventsLib.sol';
import {PendingLib, PendingUint192, PendingAddress} from '../libraries/PendingLib.sol';

/*
- add PendingLib for generic timelocks
- add timelock to relevant functions
- make comments according to NatSpec tags using /// three

@dev — Developer notes

@param — Describe function parameters

@return — Describe return values

@notice — End-user-facing comment (e.g., on UIs)

@inheritdoc — Inherit docs from parent functions
*/

contract Stablecoin is ERC20, ERC20Permit, ERC1363 {
	using Math for uint256;
	using SafeERC20 for ERC20;
	using PendingLib for PendingUint192;
	using PendingLib for PendingAddress;

	string private _customName;
	string private _customSymbol; // FIXME: maybe remove this. this could cause issues

	address public curator;
	PendingAddress public pendingCurator;

	address public guardian;
	PendingAddress public pendingGuardian;

	uint256 public timelock;
	PendingUint192 public pendingTimelock;

	mapping(address module => uint256) public modules;
	mapping(address module => PendingUint192) public pendingModules;

	mapping(address account => bool) public freezed;
	// TODO: pending unfreeze

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

	modifier onlyModule() {
		if (modules[_msgSender()] == 0) revert ErrorsLib.NotModuleRole(_msgSender());
		_;
	}

	modifier validModule() {
		if (modules[_msgSender()] <= block.timestamp) revert ErrorsLib.ModuleNotValid(_msgSender());
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
		if (modules[_msgSender()] > block.timestamp) return type(uint256).max;
		return super.allowance(owner, spender);
	}

	function _update(address from, address to, uint256 value) internal virtual override {
		if (freezed[from] == true) revert ErrorsLib.AccountFreezed(from);
		super._update(from, to, value);
	}

	// ---------------------------------------------------------------------------------------
	// allow minting modules to mint tokens

	function mintModule(address to, uint256 value) external validModule {
		_mint(to, value);
	}

	function burnModule(address from, uint256 _amount) external onlyModule {
		_burn(from, _amount);
	}

	function burn(uint256 _amount) external {
		_burn(_msgSender(), _amount);
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
		permit(owner, _msgSender(), value, deadline, v, r, s);
		transferFrom(owner, to, value);
	}

	// ---------------------------------------------------------------------------------------

	function setCurator(address newCurator) external onlyCurator {
		if (curator == newCurator) revert ErrorsLib.AlreadySet();
		if (pendingCurator.validAt != 0) revert ErrorsLib.AlreadyPending();
		pendingCurator.update(newCurator, timelock);
		emit EventsLib.SubmitCurator(_msgSender());
	}

	function revokePendingCurator() external onlyCurator {
		if (pendingCurator.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingCurator(_msgSender());
		delete pendingCurator;
	}

	/// @dev Only new curator can accept the new role after timelock
	function acceptCurator() external afterTimelock(pendingCurator.validAt) {
		if (pendingCurator.value != _msgSender()) revert ErrorsLib.NotCuratorRole(_msgSender());
		curator = pendingCurator.value;
		emit EventsLib.SetCurator(_msgSender(), curator);
		delete pendingCurator;
	}

	// ---------------------------------------------------------------------------------------

	function setGuardian(address newGuardian) external onlyCurator {
		if (guardian == newGuardian) revert ErrorsLib.AlreadySet();
		if (pendingGuardian.validAt != 0) revert ErrorsLib.AlreadyPending();

		if (guardian == address(0)) {
			_setGuardian(newGuardian);
		} else {
			pendingGuardian.update(newGuardian, timelock);
			emit EventsLib.SubmitGuardian(newGuardian);
		}
	}

	function revokePendingGuardian() external onlyCuratorOrGuardian {
		if (pendingGuardian.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingGuardian(_msgSender());
		delete pendingGuardian;
	}

	function acceptGuardian() external afterTimelock(pendingGuardian.validAt) {
		_setGuardian(pendingGuardian.value);
	}

	function _setGuardian(address newGuardian) internal {
		guardian = newGuardian;
		emit EventsLib.SetGuardian(_msgSender(), guardian);
		delete pendingGuardian;
	}

	// ---------------------------------------------------------------------------------------

	function setTimelock(uint256 newTimelock) public onlyCurator {
		if (timelock == newTimelock) revert ErrorsLib.AlreadySet();
		if (pendingTimelock.validAt != 0) revert ErrorsLib.AlreadyPending();
		_checkTimelockBounds(newTimelock);

		if (newTimelock > timelock) {
			_setTimelock(newTimelock);
		} else {
			// Safe "unchecked" cast because newTimelock <= MAX_TIMELOCK.
			pendingTimelock.update(uint184(newTimelock), timelock);
			emit EventsLib.SubmitTimelock(newTimelock);
		}
	}

	function revokePendingTimelock() external onlyCuratorOrGuardian {
		if (pendingTimelock.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingTimelock(_msgSender());
		delete pendingTimelock;
	}

	function acceptTimelock() external afterTimelock(pendingTimelock.validAt) {
		_setTimelock(pendingTimelock.value);
	}

	/// @dev Reverts if `newTimelock` is not within the bounds.
	function _checkTimelockBounds(uint256 newTimelock) internal pure {
		if (newTimelock > ConstantsLib.MAX_TIMELOCK) revert ErrorsLib.AboveMaxTimelock();
		if (newTimelock < ConstantsLib.MIN_TIMELOCK) revert ErrorsLib.BelowMinTimelock();
	}

	/// @dev Sets `timelock` to `newTimelock`.
	function _setTimelock(uint256 newTimelock) internal {
		timelock = newTimelock;
		emit EventsLib.SetTimelock(_msgSender(), newTimelock);
		delete pendingTimelock;
	}

	// ---------------------------------------------------------------------------------------

	function setModule(address module, uint256 expiredAt, string calldata message) external onlyCurator {
		if (modules[module] == expiredAt) revert ErrorsLib.AlreadySet();
		if (pendingModules[module].validAt != 0) revert ErrorsLib.AlreadyPending();

		if (totalSupply() == 0) {
			_setModule(module, expiredAt);
		} else {
			pendingModules[module].update(uint184(expiredAt), timelock);
			emit EventsLib.SubmitModule(module, block.timestamp + timelock, expiredAt, message);
		}
	}

	function revokePendingModule(address module) external onlyCuratorOrGuardian {
		if (pendingModules[module].validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingModule(_msgSender(), module);
		delete pendingModules[module];
	}

	function acceptModule(address module) external afterTimelock(pendingModules[module].validAt) {
		_setModule(module, pendingModules[module].value);
	}

	function _setModule(address module, uint256 expiredAt) internal {
		modules[module] = expiredAt;
		emit EventsLib.SetModule(_msgSender(), module);
		delete pendingModules[module];
	}

	// ---------------------------------------------------------------------------------------

	// freeze
}

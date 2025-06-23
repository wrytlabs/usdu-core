// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ERC1363} from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import {ConstantsLib} from './libraries/ConstantsLib.sol';
import {ErrorsLib} from './libraries/ErrorsLib.sol';
import {EventsLib} from './libraries/EventsLib.sol';
import {PendingLib, PendingUint192, PendingAddress} from './libraries/PendingLib.sol';

contract Stablecoin is ERC20, ERC20Permit, ERC1363 {
	using Math for uint256;
	using SafeERC20 for ERC20;
	using PendingLib for PendingUint192;
	using PendingLib for PendingAddress;

	address public curator;
	PendingAddress public pendingCurator;

	address public guardian;
	PendingAddress public pendingGuardian;

	uint256 public timelock;
	PendingUint192 public pendingTimelock;

	mapping(address module => uint256) public modules;
	mapping(address module => PendingUint192) public pendingModules;

	mapping(address account => uint256) public unfreeze;
	mapping(address account => PendingUint192) public pendingUnfreeze;

	// ---------------------------------------------------------------------------------------

	modifier onlyCurator() {
		verifyCurator(_msgSender());
		_;
	}

	modifier onlyGuardian() {
		verifyGuardian(_msgSender());
		_;
	}

	modifier onlyCuratorOrGuardian() {
		verifyCuratorOrGuardian(_msgSender());
		_;
	}

	modifier onlyModule() {
		verifyModule(_msgSender());
		_;
	}

	modifier validModule() {
		verifyValidModule(_msgSender());
		_;
	}

	modifier afterTimelock(uint256 validAt) {
		if (validAt == 0) revert ErrorsLib.NoPendingValue();
		if (block.timestamp < validAt) revert ErrorsLib.TimelockNotElapsed();
		_;
	}

	modifier claimPublicFee(uint256 fee) {
		if (fee < ConstantsLib.PUBLIC_FEE) revert ErrorsLib.ProposalFeeToLow(fee);
		_transfer(_msgSender(), curator, ConstantsLib.PUBLIC_FEE);
		_;
	}

	// ---------------------------------------------------------------------------------------

	constructor(string memory _name, string memory _symbol, address _curator) ERC20(_name, _symbol) ERC20Permit(_name) {
		curator = _curator;
	}

	// ---------------------------------------------------------------------------------------

	// TODO: IStablecoin
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return
			interfaceId == type(IERC20).interfaceId ||
			interfaceId == type(ERC20Permit).interfaceId ||
			// interfaceId == type(IStablecoin).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	// ---------------------------------------------------------------------------------------
	// modifier functions with public visibility

	function checkCurator(address account) public view returns (bool) {
		return account == curator;
	}

	function checkGuardian(address account) public view returns (bool) {
		return account == guardian;
	}

	function checkCuratorOrGuardian(address account) public view returns (bool) {
		return (account == curator || account == guardian);
	}

	function checkModule(address account) public view returns (bool) {
		return modules[account] > 0;
	}

	function checkValidModule(address account) public view returns (bool) {
		return modules[account] > block.timestamp;
	}

	// ---------------------------------------------------------------------------------------

	function verifyCurator(address account) public view {
		if (checkCurator(account) == false) revert ErrorsLib.NotCuratorRole(account);
	}

	function verifyGuardian(address account) public view {
		if (checkGuardian(account) == false) revert ErrorsLib.NotGuardianRole(account);
	}

	function verifyCuratorOrGuardian(address account) public view {
		if (checkCuratorOrGuardian(account) == false) revert ErrorsLib.NotCuratorNorGuardianRole(account);
	}

	function verifyModule(address account) public view {
		if (checkModule(account) == false) revert ErrorsLib.NotModuleRole(account);
	}

	function verifyValidModule(address account) public view {
		if (checkValidModule(account) == false) revert ErrorsLib.NotValidModuleRole(account);
	}

	// ---------------------------------------------------------------------------------------
	// allowance and update modifications

	function allowance(address owner, address spender) public view virtual override(ERC20, IERC20) returns (uint256) {
		if (modules[_msgSender()] > block.timestamp) return type(uint256).max;
		return super.allowance(owner, spender);
	}

	// TODO: optimize for gas?
	function _update(address from, address to, uint256 value) internal virtual override {
		uint256 since = unfreeze[from];
		if (since != 0 && since <= block.timestamp) revert ErrorsLib.AccountFreezed(from, since);
		super._update(from, to, value);
	}

	// ---------------------------------------------------------------------------------------
	// allow minting modules to mint tokens

	function mintModule(address to, uint256 value) external validModule {
		_mint(to, value);
	}

	function burnModule(address from, uint256 amount) external onlyModule {
		_burn(from, amount);
	}

	function burn(uint256 amount) external {
		_burn(_msgSender(), amount);
	}

	// ---------------------------------------------------------------------------------------

	function setCurator(address newCurator) external onlyCurator {
		if (curator == newCurator) revert ErrorsLib.AlreadySet();
		if (pendingCurator.validAt != 0) revert ErrorsLib.AlreadyPending();
		pendingCurator.update(newCurator, timelock);
		emit EventsLib.SubmitCurator(_msgSender(), newCurator, timelock);
	}

	function revokePendingCurator() external onlyCuratorOrGuardian {
		if (pendingCurator.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingCurator(_msgSender(), pendingCurator.value);
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
			emit EventsLib.SubmitGuardian(_msgSender(), newGuardian, timelock);
		}
	}

	function revokePendingGuardian() external onlyCuratorOrGuardian {
		if (pendingGuardian.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingGuardian(_msgSender(), pendingGuardian.value);
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
			emit EventsLib.SubmitTimelock(_msgSender(), newTimelock, timelock);
		}
	}

	function revokePendingTimelock() external onlyCuratorOrGuardian {
		if (pendingTimelock.validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingTimelock(_msgSender(), pendingTimelock.value);
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
			emit EventsLib.SubmitModule(_msgSender(), module, expiredAt, message, timelock);
		}
	}

	function setModulePublic(address module, uint256 expiredAt, string calldata message, uint256 fee) external claimPublicFee(fee) {
		if (modules[module] == expiredAt) revert ErrorsLib.AlreadySet();
		if (pendingModules[module].validAt != 0) revert ErrorsLib.AlreadyPending();

		pendingModules[module].update(uint184(expiredAt), timelock * 2);
		emit EventsLib.SubmitModule(_msgSender(), module, expiredAt, message, timelock * 2);
	}

	function revokePendingModule(address module, string calldata message) external onlyCuratorOrGuardian {
		if (pendingModules[module].validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokePendingModule(_msgSender(), module, message);
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

	function setFreeze(address account, string calldata message) external onlyCurator {
		if (unfreeze[account] > 0) revert ErrorsLib.AlreadySet();
		unfreeze[account] = block.timestamp;
		emit EventsLib.SetFreeze(_msgSender(), account, message);
	}

	// ---------------------------------------------------------------------------------------

	function setUnfreeze(address account, string calldata message) external onlyCuratorOrGuardian {
		if (unfreeze[account] == 0) revert ErrorsLib.AlreadySet();
		if (pendingUnfreeze[account].validAt != 0) revert ErrorsLib.AlreadyPending();

		pendingUnfreeze[account].update(uint184(0), timelock * 2);
		emit EventsLib.SubmitUnfreeze(_msgSender(), account, message, timelock * 2);
	}

	function revokePendingUnfreeze(address account, string calldata message) external onlyCuratorOrGuardian {
		if (pendingUnfreeze[account].validAt == 0) revert ErrorsLib.NoPendingValue();
		emit EventsLib.RevokeUnfreeze(_msgSender(), account, message);
		delete pendingUnfreeze[account];
	}

	function acceptUnfreeze(address account) external afterTimelock(pendingUnfreeze[account].validAt) {
		unfreeze[account] = 0;
		emit EventsLib.SetUnfreeze(_msgSender(), account);
		delete pendingUnfreeze[account];
	}
}

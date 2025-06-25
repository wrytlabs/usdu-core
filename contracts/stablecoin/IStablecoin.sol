// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStablecoin is IERC20 {
	// ---------------------------------------------------------------------------------------

	function checkCurator(address account) external view returns (bool);

	function checkGuardian(address account) external view returns (bool);

	function checkCuratorOrGuardian(address account) external view returns (bool);

	function checkModule(address account) external view returns (bool);

	function checkValidModule(address account) external view returns (bool);

	// ---------------------------------------------------------------------------------------

	function verifyCurator(address account) external view;

	function verifyGuardian(address account) external view;

	function verifyCuratorOrGuardian(address account) external view;

	function verifyModule(address account) external view;

	function verifyValidModule(address account) external view;

	// ---------------------------------------------------------------------------------------

	function mintModule(address to, uint256 value) external; // validModule

	function burnModule(address from, uint256 amount) external; // onlyModule

	function burn(uint256 amount) external; // public role

	// ---------------------------------------------------------------------------------------

	function setCurator(address newCurator) external; // onlyCurator

	function setCuratorPublic(address newCurator, uint256 fee) external; // claimPublicFee(fee, ConstantsLib.PUBLIC_FEE * 10)

	function revokePendingCurator() external; // onlyCuratorOrGuardian

	function acceptCurator() external; // afterTimelock(pendingCurator.validAt)

	// ---------------------------------------------------------------------------------------

	function setGuardian(address newGuardian) external; // onlyCurator

	function revokePendingGuardian() external; // onlyCuratorOrGuardian

	function acceptGuardian() external; // afterTimelock(pendingGuardian.validAt)

	// ---------------------------------------------------------------------------------------

	function setTimelock(uint256 newTimelock) external; // onlyCurator

	function revokePendingTimelock() external; // onlyCuratorOrGuardian

	function acceptTimelock() external; // afterTimelock(pendingTimelock.validAt)

	// ---------------------------------------------------------------------------------------

	function setModule(address module, uint256 expiredAt, string calldata message) external; // onlyCurator

	function setModulePublic(address module, uint256 expiredAt, string calldata message, uint256 fee) external; // claimPublicFee(fee, ConstantsLib.PUBLIC_FEE)

	function revokePendingModule(address module, string calldata message) external; // onlyCuratorOrGuardian

	function acceptModule(address module) external; // afterTimelock(pendingModules[module].validAt)

	// ---------------------------------------------------------------------------------------

	function setFreeze(address account, string calldata message) external; // onlyCurator

	// ---------------------------------------------------------------------------------------

	function setUnfreeze(address account, string calldata message) external; // onlyCuratorOrGuardian

	function revokePendingUnfreeze(address account, string calldata message) external; // onlyCuratorOrGuardian

	function acceptUnfreeze(address account) external; // afterTimelock(pendingUnfreeze[account].validAt)

	// ---------------------------------------------------------------------------------------
}

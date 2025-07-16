// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IStablecoin} from './IStablecoin.sol';
import {PendingLib, PendingUint192, PendingAddress} from './libraries/PendingLib.sol';

interface IStablecoinMetadata is IStablecoin {
	function curator() external view returns (address);

	function pendingCurator() external view returns (PendingAddress memory);

	function guardian() external view returns (address);

	function pendingGuardian() external view returns (PendingAddress memory);

	function timelock() external view returns (uint256);

	function pendingTimelock() external view returns (PendingUint192 memory);

	function modules(address module) external view returns (uint256);

	function pendingModules(address module) external view returns (PendingUint192 memory);

	function unfreeze(address account) external view returns (uint256);

	function pendingUnfreeze(address account) external view returns (PendingUint192 memory);
}

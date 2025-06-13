// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {ErrorsLib} from './ErrorsLib.sol';

struct ModuleAccess {
	address module;
	uint64 validAt;
	uint64 expiredAt;
	bool allowance;
	uint256 limit;
	uint256 minted;
}

library ModuleAccessLib {
	function mint(ModuleAccess storage module, uint256 value) internal {
		if (module.minted + value > module.limit) revert ErrorsLib.ModuleMintLimitExceeded(module.minted, module.limit);
		module.minted += value;
	}

	function burn(ModuleAccess storage module, uint256 value) internal {
		if (module.minted < value) revert ErrorsLib.ModuleBurnLimitExceeded(module.minted, value);
		module.minted -= value;
	}

	function update(
		ModuleAccess storage pending,
		address module,
		uint64 expiredAt,
		bool allowance,
		uint256 limit,
		uint256 timelock
	) internal {
		pending.module = module;
		// Safe "unchecked" cast because timelock <= MAX_TIMELOCK.
		pending.validAt = uint64(block.timestamp + timelock);
		pending.expiredAt = expiredAt;
		pending.allowance = allowance;
		pending.limit = limit;
	}
}

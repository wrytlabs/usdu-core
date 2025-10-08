// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Stablecoin, IERC20, IERC4626, VaultsAdapterV1, SafeERC20} from './VaultsAdapterV1.sol';

/**
 * @title VaultsAdapterRecoverV1
 * @author @samclassix <samclassix@proton.me>, @wrytlabs <wrytlabs@proton.me>
 * @notice This is an adapter for interacting with vaults to mint liquidity straight into them.
 */
contract VaultsAdapterRecoverV1 is VaultsAdapterV1 {
	using SafeERC20 for IERC20;

	constructor(
		Stablecoin _stable,
		IERC4626 _vault,
		address[5] memory _receivers,
		uint32[5] memory _weights
	) VaultsAdapterV1(_stable, _vault, _receivers, _weights) {}

	function recoverAll(address token) external onlyCurator {
		IERC20(token).safeTransfer(stable.curator(), IERC20(token).balanceOf(address(this)));
	}

	function recover(address token, uint256 amount) external onlyCurator {
		IERC20(token).safeTransfer(stable.curator(), amount);
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {RewardDistributionV1, Stablecoin} from '../reward/RewardDistributionV1.sol';
import {ITermMaxVault} from './ITermMaxVault.sol';

/**
 * @title TermMaxVaultAdapter
 * @author @samclassix <samclassix@proton.me>, @wrytlabs <wrytlabs@proton.me>
 * @notice Specialized adapter for TermMax vaults that implement ERC4626Updatable
 */
contract TermMaxVaultAdapter is RewardDistributionV1 {
	using Math for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for Stablecoin;

	ITermMaxVault public immutable vault;

	uint256 public totalMinted;
	uint256 public totalRevenue;

	// ---------------------------------------------------------------------------------------

	event Deposit(uint256 amount, uint256 sharesCore, uint256 totalMinted);
	event Redeem(uint256 amount, uint256 sharesCore, uint256 totalMinted);
	event Revenue(uint256 amount, uint256 totalRevenue, uint256 totalMinted);

	// ---------------------------------------------------------------------------------------

	error NothingToReconcile(uint256 assets, uint256 minted);
	error VaultPaused();
	error DepositCapExceeded(uint256 requested, uint256 available);
	error InsufficientShares(uint256 requested, uint256 available);

	// ---------------------------------------------------------------------------------------

	constructor(
		Stablecoin _stable,
		ITermMaxVault _vault,
		address[5] memory _receivers,
		uint32[5] memory _weights
	) RewardDistributionV1(_stable, _receivers, _weights) {
		vault = _vault;
	}

	// ---------------------------------------------------------------------------------------

	function totalAssets() public view returns (uint256) {
		uint256 shares = vault.balanceOf(address(this));
		if (shares == 0) return 0;

		// Use vault's totalAssets calculation which includes accrued interest
		return vault.convertToAssets(shares);
	}

	// ---------------------------------------------------------------------------------------

	function deposit(uint256 amount) external onlyCurator {
		// Check if vault is paused
		if (vault.paused()) {
			revert VaultPaused();
		}

		// Check deposit capacity
		uint256 maxDepositAmount = vault.maxDeposit(address(this));
		if (amount > maxDepositAmount) {
			revert DepositCapExceeded(amount, maxDepositAmount);
		}

		// mint stables
		stable.mintModule(address(this), amount);
		totalMinted += amount;

		// approve stable for deposit into vault
		stable.forceApprove(address(vault), amount);
		uint256 sharesCore = vault.deposit(amount, address(this));

		emit Deposit(amount, sharesCore, totalMinted);
	}

	// ---------------------------------------------------------------------------------------

	function redeem(uint256 sharesCore) external onlyCurator {
		// Check if vault is paused
		if (vault.paused()) {
			revert VaultPaused();
		}

		// If sharesCore is 0, redeem all shares
		if (sharesCore == 0) {
			sharesCore = vault.balanceOf(address(this));
		}

		// Verify we have enough shares
		uint256 availableShares = vault.balanceOf(address(this));
		if (sharesCore > availableShares) {
			revert InsufficientShares(sharesCore, availableShares);
		}

		// reconcile before redemption to account for any accrued interest
		_reconcile(totalAssets(), true);

		// redeem vault shares for stables
		vault.redeem(sharesCore, address(this), address(this));
		uint256 amount = stable.balanceOf(address(this));

		// reduce minted amount
		if (totalMinted >= amount) {
			stable.burn(amount);
			totalMinted -= amount;
		} else {
			// fallback, burn existing totalMinted if available
			if (totalMinted > 0) {
				stable.burn(totalMinted);
				totalMinted = 0;
			}

			// fallback, distribute remaining balance
			_distribute();
		}

		emit Redeem(amount, sharesCore, totalMinted);
	}

	// ---------------------------------------------------------------------------------------

	function reconcile() external {
		_reconcile(totalAssets(), false);
	}

	function _reconcile(uint256 assets, bool allowPassing) internal returns (uint256) {
		if (assets > totalMinted) {
			// calc revenue
			uint256 mintToReconcile = assets - totalMinted;
			totalRevenue += mintToReconcile;

			// mint revenue to reconcile
			stable.mintModule(address(this), mintToReconcile);
			totalMinted += mintToReconcile;
			emit Revenue(mintToReconcile, totalRevenue, totalMinted);

			// distribute balance
			_distribute();

			return mintToReconcile;
		} else {
			if (allowPassing) {
				return 0;
			} else {
				revert NothingToReconcile(assets, totalMinted);
			}
		}
	}

	// ---------------------------------------------------------------------------------------

	function recoverAll(address token) external onlyCurator {
		IERC20(token).safeTransfer(stable.curator(), IERC20(token).balanceOf(address(this)));
	}

	function recover(address token, uint256 amount) external onlyCurator {
		IERC20(token).safeTransfer(stable.curator(), amount);
	}

	// ---------------------------------------------------------------------------------------
	// TermMax-specific view functions for monitoring
	// ---------------------------------------------------------------------------------------

	function vaultInfo()
		external
		view
		returns (bool isPaused, uint256 depositCap, uint256 currentAssets, uint256 minApy, uint256 performanceFee)
	{
		isPaused = vault.paused();
		depositCap = vault.depositCap();
		currentAssets = vault.totalAssets();
		minApy = vault.minApy();
		performanceFee = vault.performanceFee();
	}

	function maxDeposit() external view returns (uint256) {
		return vault.maxDeposit(address(this));
	}
}

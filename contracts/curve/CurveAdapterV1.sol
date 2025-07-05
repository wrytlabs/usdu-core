// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {IStablecoin} from '../stablecoin/Stablecoin.sol';
import {ICurveStableSwapNG} from './helpers/ICurveStableSwapNG.sol';

contract CurveAdapterV1 {
	using Math for uint256;
	using SafeERC20 for IERC20Metadata;
	using SafeERC20 for IStablecoin;

	ICurveStableSwapNG public immutable pool;
	IStablecoin public immutable stable; // TODO: might change to IERC20Metadata
	IERC20Metadata public immutable coin;

	uint256 public immutable idxS;
	uint256 public immutable idxC;

	uint256 public totalMinted;

	// ---------------------------------------------------------------------------------------

	error NotUnderBalanced();

	// ---------------------------------------------------------------------------------------

	constructor(
		ICurveStableSwapNG _pool,
		uint256 _idxS, // IStablecoin
		uint256 _idxC // IERC20 coin
	) {
		pool = _pool;
		idxS = _idxS;
		idxC = _idxC;
		stable = IStablecoin(_pool.coins(_idxS));
		coin = IERC20Metadata(_pool.coins(_idxC));
	}

	function totalAssets() public view returns (uint256) {
		return (pool.get_virtual_price() * pool.balanceOf(address(this))) / 1 ether;
	}

	function addLiquidity(uint256 amount) external returns (uint256) {
		// check imbalance
		if (pool.balances(idxS) > (pool.balances(idxC) * 1 ether) / 10 ** coin.decimals()) {
			revert NotUnderBalanced();
		}

		uint256 amountStable = (amount * 1 ether) / 10 ** coin.decimals();

		// transfer coin token, needs approval
		coin.safeTransferFrom(msg.sender, address(this), amount);

		// mint the same amountStable in stables
		stable.mintModule(address(this), amountStable);
		totalMinted += amountStable;

		// approve tokens
		stable.forceApprove(address(pool), amountStable);
		coin.forceApprove(address(pool), amount);

		// prepare amounts
		uint256[] memory amounts = new uint256[](2);
		amounts[idxS] = amountStable;
		amounts[idxC] = amount;

		// provide liquidity
		uint256 shares = pool.add_liquidity(amounts, 0); // FIXME: calc LP min

		// return sender's portion of shares
		uint256 portion = shares / 2;
		pool.transfer(msg.sender, portion);

		// emit event

		return portion;
	}

	function removeLiquidity(uint256 shares) external returns (uint256) {
		// check imbalance
		if (pool.balances(idxS) < (pool.balances(idxC) * 1 ether) / 10 ** coin.decimals()) {
			revert NotUnderBalanced();
		}

		// transfer LP shares, needs approval
		pool.transferFrom(msg.sender, address(this), shares);

		// prepare amounts
		uint256[] memory amounts;
		amounts[0] = 0; // FIXME: calc min.
		amounts[1] = 0; // FIXME: calc min.

		uint256[] memory tokens = pool.remove_liquidity(shares * 2, amounts);

		// burn
		// _reconcile()

		// transfer
		coin.transfer(msg.sender, tokens[idxC]);

		// emit

		return 0;
	}
}

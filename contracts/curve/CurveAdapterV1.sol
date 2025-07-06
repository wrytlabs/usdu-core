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
	IStablecoin public immutable stable;
	IERC20Metadata public immutable coin;

	uint256 public immutable idxS;
	uint256 public immutable idxC;

	uint256 public totalMinted;

	// ---------------------------------------------------------------------------------------

	event AddLiquidity(address indexed sender, uint256 minted, uint256 totalMinted, uint256 sharesMinted, uint256 totalShares);
	event RemoveLiquidity(address indexed sender, uint256 burned, uint256 totalMinted, uint256 sharesBurned, uint256 totalShares);
	event Log(string message, uint256 value);

	// ---------------------------------------------------------------------------------------

	error ImbalancedVariant(uint256[] balances);
	error NotProfitable();

	// ---------------------------------------------------------------------------------------

	constructor(
		ICurveStableSwapNG _pool,
		uint256 _idxS, // IStablecoin
		uint256 _idxC // IERC20 coin
	) {
		pool = _pool;

		require(_idxS < 8, 'idxS out of bounds for max 8 tokens');
		require(_idxC < 8, 'idxC out of bounds for max 8 tokens');

		idxS = _idxS;
		idxC = _idxC;

		stable = IStablecoin(_pool.coins(_idxS));
		coin = IERC20Metadata(_pool.coins(_idxC));
	}

	// ---------------------------------------------------------------------------------------

	function checkImbalance() public view returns (bool) {
		uint256 correctedAmount = (pool.balances(idxC) * 1 ether) / 10 ** coin.decimals();
		if (pool.balances(idxS) <= correctedAmount) {
			return true;
		} else {
			return false;
		}
	}

	function verifyImbalance(bool state) public view {
		if (checkImbalance() != state) revert ImbalancedVariant(pool.get_balances());
	}

	// ---------------------------------------------------------------------------------------

	function addLiquidity(uint256 amount, uint256 minShares) external returns (uint256) {
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
		uint256 shares = pool.add_liquidity(amounts, minShares * 2);

		// verify imbalance
		verifyImbalance(true);

		// return sender's split of shares
		uint256 split = shares / 2;
		pool.transfer(msg.sender, split);

		// emit event and return share split
		emit AddLiquidity(msg.sender, amountStable, totalMinted, split, pool.balanceOf(address(this)));
		return split;
	}

	// ---------------------------------------------------------------------------------------

	function checkProfitability(uint256 beforeLP, uint256 afterLP, uint256 split) public view returns (bool) {
		if (1 ether - ((afterLP * 1 ether) / beforeLP) <= (split * 1 ether) / totalMinted) {
			return true;
		} else {
			return false;
		}
	}

	function verifyProfitability(uint256 beforeLP, uint256 afterLP, uint256 split) public view {
		if (checkProfitability(beforeLP, afterLP, split) == false) revert NotProfitable();
	}

	// ---------------------------------------------------------------------------------------

	function removeLiquidity(uint256 shares, uint256 minAmount) external returns (uint256) {
		// store LP balance
		uint256 beforeLP = pool.balanceOf(address(this));

		// transfer LP shares from sender, needs approval
		pool.transferFrom(msg.sender, address(this), shares);

		// remove both amount of the shares
		uint256 amount = pool.remove_liquidity_one_coin(shares * 2, int128(int256(idxS)), minAmount * 2);

		// verify imbalance
		verifyImbalance(false);

		// verify if in profit
		uint256 afterLP = pool.balanceOf(address(this));
		uint256 split = amount / 2;
		verifyProfitability(beforeLP, afterLP, split);

		// reconcile
		uint256 bal = stable.balanceOf(address(this)) - split;
		uint256 toBurn = _reconcile(bal);

		// transfer split to sender
		stable.transfer(msg.sender, split);

		// emit event and return share portion
		emit RemoveLiquidity(msg.sender, toBurn, totalMinted, shares, afterLP);
		return split;
	}

	// ---------------------------------------------------------------------------------------
	// redeem, onlyCurator

	function redeem(uint256 shares, uint256 minAmount) external {
		stable.verifyCurator(msg.sender);
		pool.remove_liquidity_one_coin(shares, int128(int256(idxS)), minAmount);
	}

	// ---------------------------------------------------------------------------------------

	function _reconcile(uint256 amount) internal returns (uint256) {
		uint256 toBurn = totalMinted >= amount ? amount : totalMinted;
		stable.burn(toBurn);
		totalMinted -= toBurn;
		return toBurn;
	}
}

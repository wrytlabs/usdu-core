// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

import {IMetaMorphoV1_1} from './helpers/IMetaMorphoV1_1.sol';

contract MorphoAdapterV1 is Context {
	using Math for uint256;
	using SafeERC20 for Stablecoin;
	using SafeERC20 for IMetaMorphoV1_1;

	Stablecoin immutable stable;
	IMetaMorphoV1_1 immutable core;
	IMetaMorphoV1_1 immutable staked;

	uint256 public totalMinted;
	uint256 public totalSharesCore;
	uint256 public totalSharesStaked;

	uint256 public totalRevenue;
	uint256 public ratioRevenue = 1 ether;

	address[] receivers;
	uint256[] weights;
	uint256 totalWeights;

	// ---------------------------------------------------------------------------------------

	event SetDistribution(uint256 length, uint256 totalWeights);
	event Deposit(uint256 amount, uint256 sharesCore, uint256 sharesStaked);
	event Redeem(uint256 amount, uint256 sharesCore, uint256 sharesStaked);
	event Revenue(uint256 amount, uint256 ratioAmount, uint256 totalRevenue, uint256 ratioRevenue);
	event Distribution(address indexed receiver, uint256 amount, uint256 ratio);

	// ---------------------------------------------------------------------------------------

	error ForwardCallFailed(address forwardedTo);
	error MismatchLength(uint256 receivers, uint256 weights);
	error NothingToReconcile(uint256 balance);

	// ---------------------------------------------------------------------------------------

	modifier onlyCurator() {
		stable.verifyCurator(_msgSender());
		_;
	}

	// ---------------------------------------------------------------------------------------

	constructor(Stablecoin _stable, IMetaMorphoV1_1 _core, IMetaMorphoV1_1 _staked) {
		stable = _stable;
		core = _core;
		staked = _staked;
	}

	// ---------------------------------------------------------------------------------------

	// TODO: needs a guardian step before applying ???

	function forwardToCore(bytes calldata data) external onlyCurator returns (bytes memory) {
		(bool success, bytes memory result) = address(core).call(data);
		if (!success) revert ForwardCallFailed(address(core));
		return result;
	}

	function forwardToStaked(bytes calldata data) external onlyCurator returns (bytes memory) {
		(bool success, bytes memory result) = address(staked).call(data);
		if (!success) revert ForwardCallFailed(address(staked));
		return result;
	}

	// ---------------------------------------------------------------------------------------

	// TODO: needs a guardian step before applying

	function setDistribution(address[] calldata _receivers, uint256[] calldata _weights) external onlyCurator {
		if (_receivers.length != _weights.length) revert MismatchLength(_receivers.length, _weights.length);

		// reset totalWeights
		totalWeights = 0;

		// update total weight
		uint256 len = receivers.length;
		for (uint256 i = 0; i < len; i++) {
			totalWeights += weights[i];
		}

		// update arrays
		receivers = _receivers;
		weights = _weights;
	}

	// ---------------------------------------------------------------------------------------

	function deposit(uint256 amount) external onlyCurator {
		// mint stables
		stable.mintModule(address(this), amount);
		totalMinted += amount;

		// deposit into core vault
		stable.forceApprove(address(core), amount);
		uint256 sharesCore = core.deposit(amount, address(this));
		totalSharesCore += sharesCore;

		// deposit into staked vault
		core.forceApprove(address(staked), sharesCore);
		uint256 sharesStaked = staked.deposit(sharesCore, address(this));
		totalSharesStaked += sharesStaked;

		emit Deposit(amount, sharesCore, sharesStaked);
	}

	function redeem(uint256 sharesStaked) external onlyCurator {
		// withdraw from staked vault
		staked.forceApprove(address(staked), sharesStaked);
		uint256 sharesCore = staked.redeem(sharesStaked, address(this), address(this));
		totalSharesStaked -= sharesStaked; // unchecked, static shares

		// withdraw from core vault
		core.forceApprove(address(core), sharesCore);
		uint256 amount = core.redeem(sharesCore, address(this), address(this));
		if (totalSharesCore > sharesCore) {
			totalSharesCore -= sharesCore;
		} else {
			// meaning, this module paid everything off with its revenue
			totalSharesCore = 0;
		}

		if (totalMinted == 0 || totalSharesCore == 0) {
			totalRevenue += amount;
			emit Revenue(amount, 0, totalRevenue, ratioRevenue);
			_distribute(amount);
		} else {
			// TODO: make calculation, e.g.:
			// uint256 reduceMinted = (sharesCore/totalSharesCore) * totalMinted;
			// stable.burnModule(address(this), reduceMinted);
			// uint256 revenue = amount - reduceMinted;
			// _distribute(revenue);
		}
	}

	function reconcile() external {
		// TODO: available to be called by anyone?
		uint256 assetsFromStaked = staked.convertToAssets(totalSharesStaked);
		uint256 assetsFromCore = core.convertToAssets(assetsFromStaked);

		if (assetsFromCore > totalMinted) {
			uint256 mintToReconcile = assetsFromCore - totalMinted;
			totalRevenue += mintToReconcile;

			uint256 ratioReconcile = (mintToReconcile * 1 ether) / totalMinted;
			ratioRevenue += ratioReconcile;

			emit Revenue(mintToReconcile, ratioReconcile, totalRevenue, ratioRevenue);

			stable.mintModule(address(this), mintToReconcile);
			_distribute(mintToReconcile);
		} else {
			revert NothingToReconcile(assetsFromCore);
		}
	}

	function _distribute(uint256 amount) internal {
		uint256 len = receivers.length;
		for (uint256 i = 0; i < len; i++) {
			address receiver = receivers[i];
			uint256 weight = weights[i];
			uint256 split;

			// last item?
			if (i == len - 1) {
				// distribute remainings, eliminating rounding issues
				split = stable.balanceOf(address(this));
			} else {
				// distribute weighted split
				split = (weight * amount) / totalWeights;
			}

			stable.transfer(receiver, split);
			emit Distribution(receiver, split, (weight * 1 ether) / totalWeights);
		}
	}
}

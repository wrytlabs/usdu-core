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
	uint256 public totalRevenue;

	address[] receivers;
	uint256[] weights;
	uint256 totalWeights;

	// ---------------------------------------------------------------------------------------

	event SetDistribution(uint256 length, uint256 totalWeights);
	event Deposit(uint256 amount, uint256 sharesCore, uint256 sharesStaked, uint256 totalMinted);
	event Redeem(uint256 amount, uint256 sharesCore, uint256 sharesStaked, uint256 totalMinted);
	event Revenue(uint256 amount, uint256 totalRevenue, uint256 totalMinted);
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
		for (uint256 i = 0; i < receivers.length; i++) {
			totalWeights += weights[i];
		}

		// update distribution
		receivers = _receivers;
		weights = _weights;
	}

	function revokePendingDistribution() external {}

	function applyDistribution() external {}

	function _setDistribution() internal {}

	// ---------------------------------------------------------------------------------------

	function deposit(uint256 amount) external onlyCurator {
		// mint stables
		stable.mintModule(address(this), amount);
		totalMinted += amount;

		// approve stable for deposit into core vault
		stable.forceApprove(address(core), amount);
		uint256 sharesCore = core.deposit(amount, address(this));

		// approve core shares for deposit into staked vault
		core.forceApprove(address(staked), sharesCore);
		uint256 sharesStaked = staked.deposit(sharesCore, address(this));

		emit Deposit(amount, sharesCore, sharesStaked, totalMinted);
	}

	// ---------------------------------------------------------------------------------------

	function redeem(uint256 sharesStaked) external onlyCurator {
		// approve staked shares for redeem from staked vault
		staked.forceApprove(address(staked), sharesStaked);
		uint256 sharesCore = staked.redeem(sharesStaked, address(this), address(this));

		// approve core shares for redeem from core vault
		core.forceApprove(address(core), sharesCore);
		uint256 amount = core.redeem(sharesCore, address(this), address(this));

		// reconcile, removing assets keeps accounting accurate, triggers "accrueInterest" in attached markets
		uint256 _convertToAssets = convertToAssets();
		_reconcile(_convertToAssets + amount, true);

		// reduce minted amount
		if (totalMinted > amount) {
			stable.burn(amount);
			totalMinted -= amount;
		} else {
			stable.burn(totalMinted);
			totalMinted = 0;

			uint256 bal = stable.balanceOf(address(this));
			if (bal > 0) {
				_distribute(bal);
			}
		}

		emit Redeem(amount, sharesCore, sharesStaked, totalMinted);
	}

	// ---------------------------------------------------------------------------------------

	// TODO: does this trigger "accrueInterest" in attached markets?
	// still if not, accounting would be just deplayed
	function convertToAssets() public view returns (uint256) {
		uint256 assetsFromStaked = staked.convertToAssets(staked.balanceOf(address(this)));
		return core.convertToAssets(assetsFromStaked);
	}

	function reconcile() public {
		_reconcile(convertToAssets(), false);
	}

	function _reconcile(uint256 assets, bool allowPassing) internal returns (uint256) {
		if (assets > totalMinted) {
			uint256 mintToReconcile = assets - totalMinted;
			totalRevenue += mintToReconcile;

			stable.mintModule(address(this), mintToReconcile);
			totalMinted += mintToReconcile;
			emit Revenue(mintToReconcile, totalRevenue, totalMinted);

			_distribute(mintToReconcile);
			return mintToReconcile;
		}

		if (!allowPassing) {
			revert NothingToReconcile(assets);
		} else {
			return 0;
		}
	}

	// ---------------------------------------------------------------------------------------

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

			// distribute revenue split
			stable.transfer(receiver, split);

			// last weighted ratio might be inconsistant, due to remaining assets distribution
			emit Distribution(receiver, split, (weight * 1 ether) / totalWeights);
		}
	}
}

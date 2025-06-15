// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

import {IMetaMorphoV1_1} from './helpers/IMetaMorphoV1_1.sol';

// import {RewardRouterV1} from './RewardRouterV1.sol';

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

	// ---------------------------------------------------------------------------------------

	error ForwardCallFailed(address forwardedTo);

	// ---------------------------------------------------------------------------------------

	constructor(Stablecoin _stable, IMetaMorphoV1_1 _core, IMetaMorphoV1_1 _staked) {
		stable = _stable;
		core = _core;
		staked = _staked;
	}

	// ---------------------------------------------------------------------------------------

	// TODO: needs a guardian step before applying ???

	function forwardToCore(bytes calldata data) external returns (bytes memory) {
		stable.verifyCurator(_msgSender());
		(bool success, bytes memory result) = address(core).call(data);
		if (!success) revert ForwardCallFailed(address(core));
		return result;
	}

	function forwardToStaked(bytes calldata data) external returns (bytes memory) {
		stable.verifyCurator(_msgSender());
		(bool success, bytes memory result) = address(staked).call(data);
		if (!success) revert ForwardCallFailed(address(staked));
		return result;
	}

	// ---------------------------------------------------------------------------------------

	// TODO: needs a guardian step before applying

	function setDistribution(address[] calldata _receivers, uint256[] calldata _weights) external {
		stable.verifyCurator(_msgSender());
		receivers = _receivers;
		weights = _weights;
	}

	// ---------------------------------------------------------------------------------------

	function deposit(uint256 amount) external {
		stable.verifyCurator(_msgSender());

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

		// emit Deposit(amount, sharesCore, sharesStaked)
	}

	function redeem(uint256 sharesStaked) external {
		stable.verifyCurator(_msgSender());

		// withdraw from staked vault
		staked.forceApprove(address(staked), sharesStaked);
		uint256 sharesCore = staked.redeem(sharesStaked, address(this), address(this));
		totalSharesStaked -= sharesStaked;

		// withdraw from core vault
		core.forceApprove(address(core), sharesCore);
		uint256 amount = core.redeem(sharesCore, address(this), address(this));
		totalSharesCore -= sharesCore;

		// calc revenue
		uint256 revenue = 1;

		// burn
		stable.burnModule(address(this), amount - revenue);

		// distribute

		// emit
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

import {IMorpho, MarketParams, Id} from '../morpho/helpers/IMorpho.sol';
import {ConstantsLib} from '../morpho/helpers/ConstantsLib.sol';

import {IMetaMorphoV1_1} from '../morpho/helpers/IMetaMorphoV1_1.sol';
import {IMetaMorphoV1_1Factory} from '../morpho/helpers/IMetaMorphoV1_1Factory.sol';

import {MorphoAdapterV1} from '../morpho/MorphoAdapterV1.sol';
import {RewardRouterV1} from '../morpho/RewardRouterV1.sol';

contract VaultDeployer {
	address immutable curator;

	Stablecoin immutable stable;

	IMetaMorphoV1_1 immutable core;
	IMetaMorphoV1_1 immutable staked;

	// MorphoAdapterV1 immutable adapter;
	// RewardRouterV1 immutable reward;

	// GuardianV1 immutable guardian;

	// CurveAdapterV1 immutable curve;

	constructor(address _curator) {
		// set curator
		curator = _curator;

		// deploy stablecoin
		stable = new Stablecoin('USDU', 'USDU', address(this));

		// morpho contracts
		IMetaMorphoV1_1Factory vaultFactory = IMetaMorphoV1_1Factory(0x1897A8997241C1cD4bD0698647e4EB7213535c24);
		IMorpho morpho = IMorpho(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

		// set up morpho vaults
		core = vaultFactory.createMetaMorpho(address(this), 0, address(stable), 'USDU Core', 'sUSDU', 0);
		core.setCurator(_curator);
		core.setFeeRecipient(_curator);
		core.setFee(ConstantsLib.MAX_FEE);
		core.setSkimRecipient(_curator);
		core.setIsAllocator(0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D, true);

		staked = vaultFactory.createMetaMorpho(address(this), 0, address(core), 'USDU Staked', 'ssUSDU', 0);
		staked.setCurator(_curator);
		staked.setFeeRecipient(_curator);
		staked.setFee(ConstantsLib.MAX_FEE);
		staked.setSkimRecipient(_curator);
		staked.setIsAllocator(0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D, true);

		// set up guardian
		//

		// set up markets
		MarketParams memory marketStableIdle = MarketParams(address(stable), address(0), address(0), address(0), 0);
		MarketParams memory marketStakedIdle = MarketParams(address(core), address(0), address(0), address(0), 0);
		morpho.createMarket(marketStableIdle);
		morpho.createMarket(marketStakedIdle);

		// attach markets to core vaults
		core.submitCap(marketStakedIdle, type(uint184).max);
		core.acceptCap(marketStakedIdle);

		// attach markets to staked vaults
		staked.submitCap(marketStableIdle, type(uint184).max);
		staked.acceptCap(marketStableIdle);

		/*
		
		// set up morpho adapter and reward router
		adapter = new MorphoAdapterV1(stable, core, staked);
		reward = new RewardRouterV1(0x330eefa8a787552DC5cAd3C3cA644844B1E61Ddb, _curator);

		address[] memory receivers;
		receivers[0] = address(reward);
		uint256[] memory weights;
		weights[0] = 1000;
		adapter.setDistribution(receivers, weights);

		// set up curve adapter
		// curve = new CurveAdapterV1(stable, ...);

		// set up modules
		stable.setModule(address(adapter), type(uint256).max, 'MorphoAdapterV1');
		// stable.setModule(address(curve), type(uint256).max, 'CurveAdapterV1');

		// prepare stable for curator
		stable.setCurator(curator); // no timelock, new curator needs to accept role
		stable.setTimelock(7 days); // will apply now for further steps

		*/
	}

	function finalize() external {
		// core.setSupplyQueue();
		// core.setWithdrawQueue();
		// prepare vaults for curator
		// core.
	}
}

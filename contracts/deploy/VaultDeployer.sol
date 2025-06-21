// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {Stablecoin} from '../stablecoin/Stablecoin.sol';

import {IMorpho, MarketParams} from '../morpho/helpers/IMorpho.sol';
import {ConstantsLib} from '../morpho/helpers/ConstantsLib.sol';

import {IMetaMorphoV1_1} from '../morpho/helpers/IMetaMorphoV1_1.sol';
import {IMetaMorphoV1_1Factory} from '../morpho/helpers/IMetaMorphoV1_1Factory.sol';

import {MorphoAdapterV1} from '../morpho/MorphoAdapterV1.sol';

contract TestDeployer {
	Stablecoin immutable stable;
	address immutable curator;

	IMetaMorphoV1_1 immutable core;
	IMetaMorphoV1_1 immutable staked;

	MorphoAdapterV1 immutable adapter;

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
		core.setFee(ConstantsLib.MAX_FEE);
		core.setSkimRecipient(_curator);
		core.setIsAllocator(0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D, true);

		staked = vaultFactory.createMetaMorpho(address(this), 0, address(core), 'USDU Staked', 'ssUSDU', 0);
		staked.setCurator(_curator);
		staked.setFee(ConstantsLib.MAX_FEE);
		staked.setSkimRecipient(_curator);
		staked.setIsAllocator(0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D, true);

		// set up markets
		MarketParams memory marketStableIdle = MarketParams(address(stable), address(0), address(0), address(0), 0);
		MarketParams memory marketStakedIdle = MarketParams(address(core), address(0), address(0), address(0), 0);
		morpho.createMarket(marketStableIdle);
		morpho.createMarket(marketStakedIdle);

		// attach markets to core vaults
		core.submitCap(marketStakedIdle, type(uint256).max);
		core.acceptCap(marketStakedIdle);

		// attach markets to staked vaults
		staked.submitCap(marketStableIdle, type(uint256).max);
		staked.acceptCap(marketStableIdle);

		// set up adapter
		adapter = new MorphoAdapterV1(stable, core, staked);

		// set up modules
		stable.setModule(address(adapter), type(uint256).max, 'MorphoAdapterV1');
		// stable.setModule(address(curve), type(uint256).max, 'CurveAdapterV1');

		// prepare stable for curator
		stable.setCurator(curator); // no timelock, new curator needs to accept role
		stable.setTimelock(7 days); // will apply now for further steps
	}

	function finalize() external {
		// core.setSupplyQueue();
		// core.setWithdrawQueue();
		// prepare vaults for curator
		// core.
	}
}

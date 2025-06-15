import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { ADDRESS } from '../../exports/address.config';
import { Address } from 'viem';
import { mainnet } from 'viem/chains';
import { getAddressFromChildIndex } from '../../helper/wallet';

// config and select
export const NAME: string = 'RewardsV1'; // <-- select smart contract
export const FILE: string = 'RewardsV1'; // <-- name exported file
export const MOD: string = NAME + 'Module';
console.log(NAME);

// params
export type DeploymentParams = {
	urd: Address;
	owner: Address;
};

export const params: DeploymentParams = {
	urd: ADDRESS[mainnet.id].morphoURD,
	owner: getAddressFromChildIndex(
		process.env.DEPLOYER_SEED ?? '',
		parseInt(process.env.DEPLOYER_SEED_INDEX ?? '0')
	) as Address,
};

export type ConstructorArgs = [Address, Address];

export const args: ConstructorArgs = [params.urd, params.owner];

console.log('Imported Params:');
console.log(params);

// export args
storeConstructorArgs(FILE, args);
console.log('Constructor Args');
console.log(args);

// fail safe
process.exit();

export default buildModule(MOD, (m) => {
	return {
		[NAME]: m.contract(NAME, args),
	};
});

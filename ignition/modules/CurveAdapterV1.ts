import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { ADDRESS } from '../../exports/address.config';
import { Address } from 'viem';
import { mainnet } from 'viem/chains';

// config and select
export const NAME: string = 'CurveAdapterV1'; // <-- select smart contract
export const FILE: string = 'CurveAdapterV1'; // <-- name exported file
export const MOD: string = NAME + 'Module';
console.log(NAME);

// params
export type DeploymentParams = {
	pool: Address;
	idxS: number;
	idxC: number;
};

export const params: DeploymentParams = {
	pool: ADDRESS[mainnet.id].curveStableSwapNG_USDUUSDC,
	idxS: 0,
	idxC: 1,
};

export type ConstructorArgs = [Address, number, number];

export const args: ConstructorArgs = [params.pool, params.idxS, params.idxC];

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

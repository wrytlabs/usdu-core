import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { ADDRESS } from '../../exports/address.config';
import { Address } from 'viem';
import { mainnet } from 'viem/chains';
import { getAddressFromChildIndex } from '../../helper/wallet';

// config and select
export const NAME: string = 'RewardRouterV0'; // <-- select smart contract
export const FILE: string = 'RewardRouterV0'; // <-- name exported file
export const MOD: string = NAME + 'Module';
console.log(NAME);

// params
export type DeploymentParams = {
	stable: Address;
	urd: Address;
};

export const params: DeploymentParams = {
	stable: ADDRESS[mainnet.id].usduStable,
	urd: ADDRESS[mainnet.id].morphoURD,
};

export type ConstructorArgs = [Address, Address];

export const args: ConstructorArgs = [params.stable, params.urd];

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

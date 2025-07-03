import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { Address } from 'viem';
import { ADDRESS } from '../../exports/address.config';
import { mainnet } from 'viem/chains';
const addr = ADDRESS[mainnet.id];

// config and select
export const NAME: string = 'VaultDeployer'; // <-- select smart contract
export const FILE: string = 'VaultDeployer'; // <-- name exported file
export const MOD: string = NAME + 'Module';
console.log(NAME);

// params
export type DeploymentParams = {
	morpho: Address;
	factory: Address;
	allocator: Address;
	urd: Address;
	curator: Address;
};

export const params: DeploymentParams = {
	morpho: addr.morphoBlue,
	factory: addr.morphoMetaMorphoFactory1_1,
	allocator: addr.morphoPublicAllocator,
	urd: addr.morphoURD,
	curator: addr.curator,
};

export type ConstructorArgs = [Address, Address, Address, Address, Address];

export const args: ConstructorArgs = [params.morpho, params.factory, params.allocator, params.urd, params.curator];

console.log('Imported Params:');
console.log(params);

// export args
storeConstructorArgs(FILE, args);
console.log('Constructor Args');
console.log(args);

// fail safe
// process.exit();

export default buildModule(MOD, (m) => {
	return {
		[NAME]: m.contract(NAME, args),
	};
});

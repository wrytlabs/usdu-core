import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { Address } from 'viem';
import { getAddressFromChildIndex } from '../../helper/wallet';
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
	curator: Address;
	morpho: Address;
	factory: Address;
	allocator: Address;
	urd: Address;
};

export const params: DeploymentParams = {
	curator: getAddressFromChildIndex(process.env.DEPLOYER_SEED ?? '', parseInt(process.env.DEPLOYER_SEED_INDEX ?? '0')) as Address,
	morpho: addr.morphoBlue,
	factory: addr.morphoMetaMorphoFactory1_1,
	allocator: addr.morphoPublicAllocator,
	urd: addr.morphoURD,
};

export type ConstructorArgs = [Address, Address, Address, Address, Address];

export const args: ConstructorArgs = [params.curator, params.morpho, params.factory, params.allocator, params.urd];

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

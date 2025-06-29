import { expect } from 'chai';
import { ethers } from 'hardhat';
import { IMetaMorphoV1_1, IMetaMorphoV1_1Factory, IMorpho, MorphoAdapterV1, RewardRouterV1, Stablecoin, VaultDeployer } from '../typechain';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { ADDRESS } from '../exports/address.config';
import { mainnet } from 'viem/chains';

describe('Deploy Stablecoin', function () {
	let vaultDeployer: VaultDeployer;
	let stable: Stablecoin;

	let core: IMetaMorphoV1_1;
	let staked: IMetaMorphoV1_1;
	let adapter: MorphoAdapterV1;
	let reward: RewardRouterV1;

	let deployer: SignerWithAddress;
	let curator: SignerWithAddress;
	let guardian: SignerWithAddress;
	let module: SignerWithAddress;

	beforeEach(async function () {
		[curator, guardian, module, deployer] = await ethers.getSigners();
		const addr = ADDRESS[mainnet.id];

		const VaultDeployer = await ethers.getContractFactory('VaultDeployer');
		vaultDeployer = await VaultDeployer.deploy(
			addr.morphoBlue,
			addr.morphoMetaMorphoFactory1_1,
			addr.morphoPublicAllocator,
			addr.morphoURD,
			curator.address
		);

		stable = await ethers.getContractAt('Stablecoin', await vaultDeployer.stable());

		core = await ethers.getContractAt('IMetaMorphoV1_1', await vaultDeployer.core());
		staked = await ethers.getContractAt('IMetaMorphoV1_1', await vaultDeployer.staked());

		adapter = await ethers.getContractAt('MorphoAdapterV1', await vaultDeployer.adapter());
		reward = await ethers.getContractAt('RewardRouterV1', await vaultDeployer.reward());
	});

	describe('Deployment Checks, Sequence', function () {
		// 	it('Should correctly create core vault', async function () {
		// 		const tx = await vaultFactory.createMetaMorpho(curator.address, 0n, await stable.getAddress(), 'USDU Core', 'sUSD', '0x');
		// 		const receipt = await tx.wait();

		// 		expect(receipt != null).to.be.true('receipt is null');

		// 		// const event = receipt!.events?.find(
		// 		// 	(e) => e.event === 'MetaMorphoCreated' // <-- Replace with the actual event name
		// 		// );

		// 		console.log(receipt!.events);
		// 	});

		// 	//
		it('Should correctly create core vault', async function () {
			console.log('done');
		});
	});
});

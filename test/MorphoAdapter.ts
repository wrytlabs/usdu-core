import { expect } from 'chai';
import { ethers } from 'hardhat';
import { IMetaMorphoV1_1, IMetaMorphoV1_1Factory, IMorpho, MorphoAdapterV1, Stablecoin } from '../typechain';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { AddressLike } from 'ethers';

describe('Deploy Stablecoin', function () {
	let stable: Stablecoin;
	let morpho: IMorpho;
	let vaultFactory: IMetaMorphoV1_1Factory;

	let core: IMetaMorphoV1_1;
	let staked: IMetaMorphoV1_1;

	let deployer: SignerWithAddress;
	let curator: SignerWithAddress;
	let guardian: SignerWithAddress;
	let module: SignerWithAddress;

	beforeEach(async function () {
		[curator, guardian, module, deployer] = await ethers.getSigners();

		const Stablecoin = await ethers.getContractFactory('Stablecoin');
		stable = await Stablecoin.deploy('USDU', 'USDU', curator.address);

		vaultFactory = await ethers.getContractAt('IMetaMorphoV1_1Factory', '0x1897A8997241C1cD4bD0698647e4EB7213535c24');
		morpho = await ethers.getContractAt('IMorpho', '0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb');
	});

	describe('Deployment Checks, Sequence', function () {
		it('Should correctly create core vault', async function () {
			const tx = await vaultFactory.createMetaMorpho(curator.address, 0n, await stable.getAddress(), 'USDU Core', 'sUSD', '0x');
			const receipt = await tx.wait();

			expect(receipt != null).to.be.true('receipt is null');

			// const event = receipt!.events?.find(
			// 	(e) => e.event === 'MetaMorphoCreated' // <-- Replace with the actual event name
			// );

			console.log(receipt!.events);
		});

		//
	});
});

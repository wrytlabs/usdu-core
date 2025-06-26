import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Stablecoin } from '../typechain';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('Deploy Stablecoin', function () {
	let stable: Stablecoin;
	let curator: SignerWithAddress;
	let guardian: SignerWithAddress;
	let module: SignerWithAddress;
	let user: SignerWithAddress;

	beforeEach(async function () {
		[curator, guardian, module, user] = await ethers.getSigners();

		const Stablecoin = await ethers.getContractFactory('Stablecoin');
		stable = await Stablecoin.deploy('USDU', 'USDU', curator.address);
	});

	describe('Role Checks, Curator Role', function () {
		it('Should correctly assigned curator role', async function () {
			expect(await stable.curator()).to.equal(curator.address);
		});

		//

		it('Should correctly checkCurator role', async function () {
			expect(await stable.checkCurator(curator.address)).to.equal(true);
		});

		//

		it('Should correctly verifyCurator role', async function () {
			expect(await stable.verifyCurator(curator.address)).to.not.be.reverted;
		});

		it('Should correctly verifyCuratorOrGuardian role', async function () {
			expect(await stable.verifyCuratorOrGuardian(curator.address)).to.not.be.reverted;
		});

		it('Should revert verifyGuardian role', async function () {
			await expect(stable.verifyGuardian(curator.address)).to.be.reverted;
		});

		it('Should revert verifyModule role', async function () {
			await expect(stable.verifyModule(curator.address)).to.be.reverted;
		});

		it('Should revert verifyValidModule role', async function () {
			await expect(stable.verifyValidModule(curator.address)).to.be.reverted;
		});
	});
});

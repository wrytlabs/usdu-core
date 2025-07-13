import { ethers, network } from 'hardhat';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('Get Signer', function () {
	let user: SignerWithAddress;
	const account = '0x55cF8D1Dc56b15F6f637982d860E7aeb6DE86DcA';

	before(async function () {
		// Impersonate USDC whale and curator
		await network.provider.request({ method: 'hardhat_impersonateAccount', params: [account] });
		user = await ethers.getSigner(account);
	});

	describe('Get Signer Details', async function () {
		let balance: bigint = 0n;

		it('Get balance', async () => {
			balance = await ethers.provider.getBalance(user.address);
			console.log(`${account}: ${balance}`);
		});
	});
});

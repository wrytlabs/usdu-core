import { arbitrum, avalanche, base, gnosis, mainnet, optimism, polygon, sonic } from 'viem/chains';
import { ChainAddressMap } from './address.types';

export const ADDRESS: ChainAddressMap = {
	[mainnet.id]: {
		// identifier
		chainId: 1,
		chainSelector: '5009297550715157269',

		// curator / DAO
		curator: '0x9fe66037c44236c87D9Ac8345F489b4413fDFf06',

		// morpho related
		morphoBlue: '0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb',
		morphoIrm: '0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC',
		morphoChainlinkOracleV2Factory: '0x3A7bB36Ee3f3eE32A60e9f2b33c1e5f2E83ad766',
		morphoMetaMorphoFactory1_1: '0x1897A8997241C1cD4bD0698647e4EB7213535c24',
		morphoPublicAllocator: '0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D',
		morphoURD: '0x330eefa8a787552DC5cAd3C3cA644844B1E61Ddb',

		// vault deployer
		usduDeployer: '0x745211a1e1a58b2b11b932855b30d411c31e25d5',
		usduStable: '0xdde3ec717f220fc6a29d6a4be73f91da5b718e55',
		usduCoreVault: '0xce22b5fb17ccbc0c5d87dc2e0df47dd71e3adc0a',
		usduStakedVault: '0x0b5281e1fa7fc7c1f0890f311d5f04d55c0fd63c',
		usduRewardRouterV0: '0xFA6d71ED122a7b3b494116317C2aC3B4E5269339', // <-- new deployment
		usduMorphoAdapterV1: '0x6D6525D8e234D840b2699f7107f14fa0D6C62c42',

		// core vault market ids
		marketIdUSDUIdle: '0x0F2C33F9074109B75B88617534E6AC6DFA8EBF97270C716782221A27CBF0D880',
		marketIdUSDUUSDC: '0x60f855f6b8c6919c2a4f3ab5f367fc923e3172e6dc8f4e8b6c448eb2d43421a1',
		marketIdUSDUWETH: '0xa6b5b5cc24a40900156a503afc6c898118b6d37ae545c2c144326fb95ac68e7a',

		// cross market ids
		marketIdUSDCUSDU: '0x6E988863B5C88C6A0038E07F346D79A941BA30E6BAB0E1267F3BCF72275D572A',
		marketIdUSDCSUSDU: '0xAC3DB6E1B107B3239C6356F7018058BA66DFC8BB9D619F90A567CA58D33FFA36',

		// curve pools
		curveStableSwapNG_USDUUSDC: '0x771c91e699B4B23420de3F81dE2aA38C4041632b',
		// https://www.curve.finance/dex/ethereum/pools/factory-stable-ng-506

		// curve adapter
		curveAdapterV1_USDC: '0x6f05782a28cDa7f01B054b014cF6cd92023937e4',

		// erc20 tokens
		usdc: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
	},
	[polygon.id]: {
		// identifier
		chainId: 137,
		chainSelector: '4051577828743386545',
	},
	[arbitrum.id]: {
		// identifier
		chainId: 42161,
		chainSelector: '4949039107694359620',
	},
	[optimism.id]: {
		// identifier
		chainId: 10,
		chainSelector: '3734403246176062136',
	},
	[base.id]: {
		// identifier
		chainId: 8453,
		chainSelector: '15971525489660198786',
	},
	[avalanche.id]: {
		// identifier
		chainId: 43114,
		chainSelector: '6433500567565415381',
	},
	[gnosis.id]: {
		// identifier
		chainId: 100,
		chainSelector: '465200170687744372',
	},
	[sonic.id]: {
		// identifier
		chainId: 146,
		chainSelector: '1673871237479749969',
	},
} as const;

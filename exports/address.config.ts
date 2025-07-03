import { arbitrum, avalanche, base, gnosis, mainnet, optimism, polygon, sonic } from 'viem/chains';
import { ChainAddressMap } from './address.types';

export const ADDRESS: ChainAddressMap = {
	[mainnet.id]: {
		// identifier
		chainId: 1,
		chainSelector: '5009297550715157269',

		// curator
		curator: '0x9fe66037c44236c87D9Ac8345F489b4413fDFf06',

		// morpho related
		morphoBlue: '0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb',
		morphoIrm: '0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC',
		morphoChainlinkOracleV2Factory: '0x3A7bB36Ee3f3eE32A60e9f2b33c1e5f2E83ad766',
		morphoMetaMorphoFactory1_1: '0x1897A8997241C1cD4bD0698647e4EB7213535c24',
		morphoPublicAllocator: '0xfd32fA2ca22c76dD6E550706Ad913FC6CE91c75D',
		morphoURD: '0x330eefa8a787552DC5cAd3C3cA644844B1E61Ddb',
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

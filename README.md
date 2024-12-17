# DeFi Wonderland Challenge

## The Task
- [x] Review the existing code
    - There are more than 20 audited issues in the code
- [x] Finish requirements (details below)
- [x] Reach full (~100%) test coverage
- [] Deploy to Sepolia
- [] Mint some Ants to `0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e` from the CryptoAnt constructor
- [] Create a Pull Request

[changelog](./changelog)


## Trade Off(s)
Allowing owners to get their owned AntId(s) or [getMyAntsId()](./src/CryptoAnts.sol#102) increases gas costs due to its use of an array to track Ant IDs per wallet. Removing it can reduce costs.

## Known Security Issues
#### Smart Contracts (Slither)
1. [weak PRNG](./src/CryptoAnts.sol#100) used for egg laying and Ant death probabilities:
`uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, antId)))`
    1) Amount of Egg to lay [0,20]
    2) Chance of Ant death when laying Egg

2. Egg laying [cooldown](./src/CryptoAnts.sol#97) uses `block.timestamp`, which can deviate by 15 minutes.

## Consideration for Production use
- Remove [_adminMintAnt()](./src/CryptoAnts.sol#43) as it allows minting Ants without using Eggs, which contradicts game rules.
- Governer can set the Ant and Egg price to 0.

#### Test Coverage
- CryptoAnts.sol: 100% branch coverage.
- Egg.sol: 100% branch coverage, 
- Governance.sol: 100% branch coverage.

## Game Logic (Requirements):
- [x] EGGs are ERC20 tokens and indivisible.
- [x] ANTs are ERC721 tokens.
- [x] Users buy EGGs with ETH at 0.01 ETH each.
- [x] EGGs create ANTs; ANTs can be sold for less than the EGG price.
- [x] Governance can change EGG prices.

#### Nice to Have
- [x] ANTs lay eggs every 10 minutes, randomly 0-20 eggs.
- [x] 1% chance of Ant death when laying eggs.

#### Additional Features
- [x] Governance can adjust Ant death probability, egg laying cooldown, and egg price.
- [x] Batch minting of Ants.
- [x] Retrieve owned Ant IDs.

#### Deployment Addresses
- ANT `ERC721`: [View on Etherscan](https://sepolia.etherscan.io/address/0x29b4e177df879de7235498822c69065654ddf00d#code)
- EGG `ERC20`: [View on Etherscan](https://sepolia.etherscan.io/address/0x3036055a339580bfe30892ab09965f29532d4741#code)

## Running the Repo

### Prerequisites
- Install [Foundry](https://github.com/foundry-rs/foundry).

### Setup Instructions
1. Clone the repo and run 
    ```bash 
    yarn install --frozen-lockfile
    ```
3. Get an API key from [Alchemy](https://www.alchemy.com/).
4. Create a `.env` file using `.env.example` as a guide.

**Note**: Avoid using accounts with ETH on the mainnet. Use the [Sepolia Faucet](https://sepolia-faucet.pk910.de/) if needed.

### Testing
Run tests with:
```bash
yarn test
```

```bash
yarn coverage
```

### Deployment
Deploy and verify contracts on Sepolia with:
```bash
yarn deploy:sepolia
```
**Note**: Verification may take a few minutes.

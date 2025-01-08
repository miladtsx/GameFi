# GameFi malad-ants
## Introduction
Malad-Ants is a decentralized game featuring resource management with ERC20 (Egg) and ERC721 (ANTs) tokens. Players can mint, trade, and Governor (EOA) can govern game elements, ensuring an engaging DeFi experience.


### Actors
- Deployer
- Governor
- Player

## Accomplishments
- [x] Achieved full (~100%) test coverage

[View the changelog](./changelog.md)

### Trade Off(s)
1) [getMyAntsId()](./src/CryptoAnts.sol#139) increases gas costs due to its array-based implementation. This feature can be removed for efficiency.

### Known Security Issues
1. [weak PRNG](./src/CryptoAnts.sol#99) Used for egg-laying and ant death probabilities. Consider integrating Chainlink VRF for a secure and reliable random number generation mechanism.
2. [Timestamp Cooldown](./src/CryptoAnts.sol#96) uses `block.timestamp`, which can deviate by 15 minutes. Replace with block numbers for greater reliability.

### Consideration for Production use
- Governer can set the Ant and Egg price to 0.

### Test Coverage
- CryptoAnts.sol: 100% branch coverage.
- Egg.sol: 100% branch coverage, 
- Governance.sol: 100% branch coverage.

### Functional Requirements
- [x] Egg is an ERC20 token and indivisibleEnable infinite minting of Ants without requiring EGGs for administrative purposes.
- [x] Ant is an ERC721 tokens (NFT).
- [x] Users buy Egg with ETH at 0.01 ETH each.
- [x] An Ant is born by burning an Egg; Ant can be sold for less than the Egg price.
- [x] ANTs lay eggs every 10 minutes, randomly 0-20 eggs.
- [x] Governance can change Egg price.
- [x] 1% chance of Ant death when laying eggs.
- [x] E2E tests

#### Nice to Have Features
- [x] Governance can adjust Ant death probability, egg laying cooldown, and Ant price.
- [x] Batch minting of Ants.
- [x] Retrieve owned Ant IDs.

#### User Security features
- [x] Prevent accidental direct ETH Transfer

#### Deployment Addresses
- Ant `ERC721`: [View on Etherscan](https://sepolia.etherscan.io/address/0xB5500E2C3B09Eb7cfb19437BF88f3b3fe739C3b6#code)
- Egg `ERC20`: [View on Etherscan](https://sepolia.etherscan.io/address/0xA8792F44636D480a74c9B854c29a9b3dcAe9704a#code)

## Running the Repo

#### Prerequisites
- Install [Foundry](https://github.com/foundry-rs/foundry).

#### Setup Instructions
1. Clone and install dependencies 
    ```bash 
    git clone --depth 1 https://github.com/miladtsx/gamefi-malad-ants
    ```

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

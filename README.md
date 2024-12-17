# DeFi Wonderland Challenge

## The Task
- [x] Review the existing code
    - There are more than 20 audited issues in the code
- [x] Finish requirements (details below)
- [x] Reach full (~100%) test coverage
- [] Deploy to Sepolia
- [] Mint some Ants to `0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e` from the CryptoAnt constructor
- [] Create a Pull Request

## Known Low Security Issues
### Smart Contracts (Slither)
> [] CryptoAnts.layEgg(uint256) (src/CryptoAnts.sol#57-75) uses a weak PRNG: "numberOfEggsToMint = randomness % 21 (src/CryptoAnts.sol#70)" 
> [] CryptoAnts.layEgg(uint256) (src/CryptoAnts.sol#57-75) uses a weak PRNG: "(randomness % 100) < antDeathProbability (src/CryptoAnts.sol#64)" 
> [] CryptoAnts.layEgg(uint256) (src/CryptoAnts.sol#56-74) uses timestamp for comparisons

## Test Coverage
| File                | % Lines         | % Statements    | % Branches      | % Funcs        |
|---------------------|-----------------|-----------------|-----------------|----------------|
|[CryptoAnts.sol](./src/CryptoAnts.sol)  | 100.00% (32/32) | 100.00% (40/40) | 100.00% (11/11) | 100.00% (9/9)  |
| [Egg.sol](./src/Egg.sol)         | 85.71% (6/7)    | 85.71% (6/7)    | 100.00% (6/6)   | 100.00% (4/4)  |
| [Governance.sol](./src/Governance.sol)  | 100.00% (10/10) | 100.00% (10/10) | 83.33% (5/6)    | 100.00% (6/6)  |

> Though Branches are 100% covered by tests, the coverage report generator fails to correctly detect.
- [Egg.sol](./src/Egg.sol#28)#decimals()
- [Governance.sol](./src/Governance.sol#18)#noZeroAddress()

### Requirements:
- [x] EGGs should be ERC20 tokens
- [x] EGGs should be indivisible
- [x] ANTs should be ERC721 tokens (**NFTs**)
- [x] Users can buy EGGs with ETH
- [x] EGGs should cost 0.01 ETH
- [x] An EGG can be used to create an ANT
- [x] An ANT can be sold for less ETH than the EGG price
- [x] Governance should be able to change the price of an EGG
- [x] Finish the end-to-end tests

#### Nice to Have
- [x] Ants should be able to create/lay eggs once every 10 minutes
- [x] Ants should be able to randomly create multiple eggs at a time (0-20 range)
- [x] Ants have a 1% chance of dying when creating eggs

#### Additional Features
- [x] Governance should be able to change the chance of an Ant dying when creating eggs
- [x] Governance should be able to change the create/lay eggs cooldown

#### Deployment Addresses
- ANT `ERC721`: [View on Etherscan](https://sepolia.etherscan.io/address/0x29b4e177df879de7235498822c69065654ddf00d#code)
- EGG `ERC20`: [View on Etherscan](https://sepolia.etherscan.io/address/0x3036055a339580bfe30892ab09965f29532d4741#code)

# Running the Repo

### Prerequisites
- Ensure you have [Foundry](https://github.com/foundry-rs/foundry) installed on your machine.

### Setup Instructions
1. Clone the repository.
2. Run the following command to install dependencies:
   ```bash
   yarn install
   ```
3. Obtain an API key from an RPC provider by creating an account at [Alchemy](https://www.alchemy.com/).
4. Create a `.env` file and complete it using the provided `.env.example` file as a guide.

**Note**: We highly discourage using accounts that may hold ETH on the mainnet to avoid unnecessary errors. If you don't hold ETH in Sepolia, you can request some from a faucet: [Sepolia Faucet](https://sepolia-faucet.pk910.de/).

### Running the Tests
To run the tests, execute:
```bash
yarn test
```

### Deploying the Contracts
To deploy and verify the contracts on Sepolia, run:
```bash
yarn deploy:sepolia
```
**Note**: The verification of the contracts may take a couple of minutes, so be patient if it seems that your terminal is stuck.

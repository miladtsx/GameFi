# DeFi Wonderland Challenge

## The Task
- [x] Review the existing code
    - There are more than 20 audited issues in the code
- [x] Finish requirements (details below)
- [x] Reach full (~100%) test coverage
- [] Deploy to Sepolia
- [] Mint some Ants to `0x7D4BF49D39374BdDeB2aa70511c2b772a0Bcf91e` from the CryptoAnt constructor
- [] Create a Pull Request

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

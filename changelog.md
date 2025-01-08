[<- back](./README.md)
# Changelog

## V1

### Features
- **LayEgg**: may die (commit [91ed8c8a](https://github.com/miladtsx/gamefi-malad-ants/commit/91ed8c8a6a623ae9a0af8e5bb196e22297d07533))
- **LayEgg**: lay 0-20 eggs randomly (commit [bc806ee9](https://github.com/miladtsx/gamefi-malad-ants/commit/bc806ee9c58ba56a812de60c5fc42f9a0dda2b3a))
- **LayEgg**: lay egg once every 10 minutes (commit [1fbceda0](https://github.com/miladtsx/gamefi-malad-ants/commit/1fbceda0790797fa25f3bc1e429cf4c030a2357b))
- **BuyEgg**: Logs buyer address (commit [679a0670](https://github.com/miladtsx/gamefi-malad-ants/commit/679a0670c3fded70e31b4db4f6cfe2a1a48fae34))
- **Governance**: Set egg laying cooldown (commit [1fbceda0](https://github.com/miladtsx/gamefi-malad-ants/commit/1fbceda0790797fa25f3bc1e429cf4c030a2357b))
- **Governance**: Set Egg price (commit [e948e97e](https://github.com/miladtsx/gamefi-malad-ants/commit/e948e97e610a7fbbb08bbf6aead93f203ad5b416))
- **Governance**: Set Ant price (commit [d7bb0aff](https://github.com/miladtsx/gamefi-malad-ants/commit/d7bb0aff47d4a906a44c1ceff0868e3f44d156f8))
- **MintAntBatch**: Batch minting of Ants (commit [0dd6980f](https://github.com/miladtsx/gamefi-malad-ants/commit/0dd6980f9aafb047d3f83fba5d37b0a81ea9d02e))
- **ReturnAntIds**: Retrieve owned Ant IDs (commit [0dd6980f](https://github.com/miladtsx/gamefi-malad-ants/commit/0dd6980f9aafb047d3f83fba5d37b0a81ea9d02e))

### Fixes
- **ReturnAntIds**: update the ant id array when deleting (commit [2d5abcfa](https://github.com/miladtsx/gamefi-malad-ants/commit/2d5abcfa9f9ccd6e5727b440a48c8a2dca3cc6ef))
- **security**: Use OpenZeppelin reentrancy guard (commit [9dbfa3cd](https://github.com/miladtsx/gamefi-malad-ants/commit/9dbfa3cdad6812d7da818dc19bdb98eb9beedd1a))
- **security**: Update packages (commit [cddbb597](https://github.com/miladtsx/gamefi-malad-ants/commit/cddbb597919db06836cdc0e1ba7e84f76b4a7f18))
- **security**: Use Stable Solidity Version (commit [8aff505e](https://github.com/miladtsx/gamefi-malad-ants/commit/8aff505e60b298e0432a53ba655d8b4964fe6029))
- **buyEggs**: Validate input, return extra ETH (commit [4b235d14](https://github.com/miladtsx/gamefi-malad-ants/commit/4b235d1481fad2178dbea18e13f4cb866f9cca09))
- **buyEggs**: check balance (commit [009851ea](https://github.com/miladtsx/gamefi-malad-ants/commit/009851eafdf5d0847a2ffecf42e865cd7d0541c8))
- **setup**: Adjust nonce (commit [0e248561](https://github.com/miladtsx/gamefi-malad-ants/commit/0e24856167066a292b25ca48a1e6f9f2b37d39a3))
- **gas**: Use immutable variables (commit [a1b9fdfb](https://github.com/miladtsx/gamefi-malad-ants/commit/a1b9fdfb8fac4da746d1d4af3c1d2c8fc02676ed))

### Refactors
- **modifier**: Implement NoZeroAddress (commit [7ff06297](https://github.com/miladtsx/gamefi-malad-ants/commit/7ff0629719f5d9f083c7bb5bfcc1b759c228bf8f))
- **authorization**: Use modifiers for access control (commit [a29f99fe](https://github.com/miladtsx/gamefi-malad-ants/commit/a29f99fe5ffd2e8cc7277690e107f804bca34434))
- **lint**: Remove redundant code (commit [3504d5bf](https://github.com/miladtsx/gamefi-malad-ants/commit/3504d5bf6bcc0d1684a32f8120a3bd5b70ad3018))
- **customError**: Improve readability and maintainability (commit [9b7b7eaf](https://github.com/miladtsx/gamefi-malad-ants/commit/9b7b7eafc3b25db4d81c7e5a72596eced545f41b))


### Tests
- **unit**: Test invalid egg count and Ant life status (commit [50fac8d5](https://github.com/miladtsx/gamefi-malad-ants/commit/50fac8d5fb2a8591ac15473c9b93cddfd3e42498))
- **eggToAnt**: Test conversion from 0 to 100 Ants per egg (commit [b4a4717a](https://github.com/miladtsx/gamefi-malad-ants/commit/b4a4717a5a4439855afbe58358ac9d0ec15e0fc4))
- **antDeath**: Test random death (commit [752d316f](https://github.com/miladtsx/gamefi-malad-ants/commit/752d316f18774342fa964ee79ca444a31a622fdd))
- **sellAnt**: Test price and burn (commit [cded7fc3](https://github.com/miladtsx/gamefi-malad-ants/commit/cded7fc3be5ecc67b9b4f932d731aedb7e8fca0d))
- **style**: Separate unit and integration tests (commit [4e6073e6](https://github.com/miladtsx/gamefi-malad-ants/commit/4e6073e604b35677bb40bd4df4590a692fe096eb))

### Styles
- **naming**: Standardize variable names (commit [e5a8cfcb](https://github.com/miladtsx/gamefi-malad-ants/commit/e5a8cfcb4b1dd0b3c0959a3338796328461635c4))

### Chores
- **readme**: Update documentation (commit [87e29cad](https://github.com/miladtsx/gamefi-malad-ants/commit/87e29cad421d3c8d877f25a113c68de6824f4497))
- **linter**: Standardize parameter names (commit [0cc9f36a](https://github.com/miladtsx/gamefi-malad-ants/commit/0cc9f36a08d990aad2d9940c3c9d3d01d6698bc3))
- **script**: Update deprecated functions (commit [1e8542f5](https://github.com/miladtsx/gamefi-malad-ants/commit/1e8542f537eaa61bba45760109d25edd5fa74428))
- **unused**: Remove notLocked (commit [c468d708](https://github.com/miladtsx/gamefi-malad-ants/commit/c468d70841d4136e4ce55bf44850c46f7d9e3897))

### backdoor
- **MintAntWithoutEgg**: Allows minting Ants without Eggs (commit [0dd6980f](https://github.com/miladtsx/gamefi-malad-ants/commit/0dd6980f9aafb047d3f83fba5d37b0a81ea9d02e))

[<- back](./README.md)

# Permit2 Payment

User specifies and signs the set of operations they want to do and an amount of ERC20 tokens they're willing to pay for
execution

Contract and verifies signature using
[Uniswap Permit2](https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/permit2) and pulls user
tokens, performs the payments.

## Getting Started

```sh
git clone git@github.com:ngduythao/permit2-payment.git
cd permit2-payment
pnpm install # install Solhint, Prettier, and other Node.js deps
```

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/DeployFoo.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ pnpm lint
```

### Test

Run the tests:

```sh
$ forge test
```

## Related Efforts

- [abigger87/femplate](https://github.com/abigger87/femplate)
- [cleanunicorn/ethereum-smartcontract-template](https://github.com/cleanunicorn/ethereum-smartcontract-template)
- [foundry-rs/forge-template](https://github.com/foundry-rs/forge-template)
- [FrankieIsLost/forge-template](https://github.com/FrankieIsLost/forge-template)
- [FrankieIsLost/forge-template](https://github.com/FrankieIsLost/forge-template)
- [PaulRBerg/hardhat-template](https://github.com/PaulRBerg/hardhat-template)

## License

This project is licensed under MIT.

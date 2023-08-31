# VRF Direct Funding COnsumer

## I. About

This is a consumer contract that allows users to pay for VRF calls in LINK. The purpose of this contract is to demonstrate how to use the Chainlink VRF Direct Funding method. This contract is not intended to be used in production. It is intended to be used as a reference for developers who want to implement the Chainlink VRF Direct Funding method in their own contracts.

## II. Pre-requisites

### 1. Clone repo

```bash
$ git clone git@github.com:linkpoolio/vrf-direct-funding-consumer.git
```

### 2. Create etherscan API key

- [Create Account](https://docs.etherscan.io/getting-started/creating-an-account)
- [Create API Key](https://docs.etherscan.io/getting-started/viewing-api-usage-st)

### 3. Create .env file

```bash
# Network RPCs
export RPC_URL=

# Private key for contract deployment
export PRIVATE_KEY=

# Explorer API key used to verify contracts
export EXPLORER_KEY=
```

### 4. Install dependencies

```bash
# root
$ make install
```

### 5. Deploy contract

```bash
# root
$ make deploy
```

### 6. Test contract

```bash
# root
$ make test
```

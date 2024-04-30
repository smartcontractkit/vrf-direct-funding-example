# VRF Direct Funding Consumer

## I. About

This is a consumer contract that allows end users to pay for VRF calls in LINK. The purpose of this contract is to demonstrate how to use the Chainlink VRF Direct Funding method to allow the end user to pay for the service. This contract is not intended to be used in production. It is intended to be used as a reference for developers who want to implement the Chainlink VRF Direct Funding method in their own contracts.

## II. Pre-requisites

**Note:** The project is currently configured for the Ethereum Sepolia network. You can add support for additional networks by extending the `HelperConfig` script in `script/HelperConfig.s.sol` with the desired network settings.

### 1. Clone repo

```bash
$ git clone https://github.com/smartcontractkit/vrf-direct-funding-example.git
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
export ETHERSCAN_API_KEY=
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

> :warning: **Disclaimer**: "This tutorial represents an educational example to use a Chainlink system, product, or service and is provided to demonstrate how to interact with Chainlink’s systems, products, and services to integrate them into your own. This template is provided “AS IS” and “AS AVAILABLE” without warranties of any kind, it has not been audited, and it may be missing key checks or error handling to make the usage of the system, product or service more clear. Do not use the code in this example in a production environment without completing your own audits and application of best practices. Neither Chainlink Labs, the Chainlink Foundation, nor Chainlink node operators are responsible for unintended outputs that are generated due to errors in code."

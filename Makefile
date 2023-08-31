-include .env

install:
	forge install --no-git Openzeppelin/openzeppelin-contracts smartcontractkit/chainlink

deploy:
	forge script script/VRFDirectFunding.s.sol:VRFDirectFundingScript --rpc-url ${RPC_URL} --etherscan-api-key ${EXPLORER_KEY} --broadcast --verify -vvvv

# test
test:
	forge test -vvvvvvv

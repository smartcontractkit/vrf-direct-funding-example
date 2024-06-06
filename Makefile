install:
	forge install Openzeppelin/openzeppelin-contracts@v4.9.6 smartcontractkit/chainlink foundry-rs/forge-std --no-git --no-commit

deploy:
	source .env && forge script script/DeployVRFDirectFunding.s.sol --rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --verify -vvvv
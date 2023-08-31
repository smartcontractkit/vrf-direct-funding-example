// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {VRFDirectFundingConsumer} from "@src/VRFDirectFundingConsumer.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract VRFDirectFundingScript is Script {
    using stdJson for string;

    VRFDirectFundingConsumer vrfDirectFundingConsumer;
    uint256 deployerPrivateKey;
    Config config;

    struct Config {
        uint32 automationCallbackGas;
        uint32 callbackGasLimit;
        address keepersRegistry;
        address linkAddress;
        string name;
        address registrarAddress;
        uint16 requestConfirmations;
        address whaleAddress;
        address wrapperAddress;
    }

    function configureNetwork(
        string memory input
    ) internal view returns (Config memory) {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/script/input/"
        );
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        string memory file = string.concat(input, ".json");
        string memory data = vm.readFile(
            string.concat(inputDir, chainDir, file)
        );
        bytes memory rawConfig = data.parseRaw("");
        return abi.decode(rawConfig, (Config));
    }

    function run() public {
        config = configureNetwork("config");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        vrfDirectFundingConsumer = new VRFDirectFundingConsumer(
            config.callbackGasLimit,
            config.linkAddress,
            config.wrapperAddress,
            config.requestConfirmations
        );

        vm.stopBroadcast();
    }
}

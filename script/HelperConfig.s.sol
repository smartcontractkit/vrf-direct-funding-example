// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address linkAddress;
        address wrapperAddress;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getEthereumSepoliaConfig();

            // } else if (block.chainid == XXX) {
            // configure other chains here
        }
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumSepoliaConfig = NetworkConfig({
            linkAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            wrapperAddress: 0x195f15F2d49d693cE265b4fB0fdDbE15b1850Cc1,
            callbackGasLimit: 500000,
            requestConfirmations: 3
        });
        return ethereumSepoliaConfig;
    }
}

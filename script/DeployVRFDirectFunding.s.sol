// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFDirectFundingConsumer} from "../src/VRFDirectFundingConsumer.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployVRFDirectFunding is Script {
    VRFDirectFundingConsumer vrfDirectFundingConsumer;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 deployerKey;

    function run() external returns (VRFDirectFundingConsumer) {
        HelperConfig helperConfig = new HelperConfig();

        (, address wrapperAddress, uint32 callbackGasLimit, uint16 requestConfirmations) =
            helperConfig.activeNetworkConfig();

        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerKey);

        vrfDirectFundingConsumer = new VRFDirectFundingConsumer(callbackGasLimit, wrapperAddress, requestConfirmations);

        vm.stopBroadcast();
        return vrfDirectFundingConsumer;
    }
}

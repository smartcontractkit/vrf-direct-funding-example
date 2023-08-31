// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";
import "@src/VRFDirectFundingConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VRFDirectFundingConsumerForkTest is Test {
    using stdJson for string;

    VRFDirectFundingConsumer vrfDirectFundingConsumer;
    LinkTokenInterface linkTokenContract;
    uint256 network;
    uint256 testNumber;
    address admin;

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

    function setUp() public {
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        config = configureNetwork("config");
        admin = makeAddr("admin");
        testNumber = 42;
        vm.startPrank(admin);
        vrfDirectFundingConsumer = new VRFDirectFundingConsumer(
            config.callbackGasLimit,
            config.linkAddress,
            config.wrapperAddress,
            config.requestConfirmations
        );
        linkTokenContract = LinkTokenInterface(config.linkAddress);
        vm.stopPrank();
    }

    function testFork_requestRandomWords() public {
        vm.selectFork(network);
        vm.prank(config.whaleAddress);
        linkTokenContract.approve(
            address(vrfDirectFundingConsumer),
            1000000000000000000
        );

        vrfDirectFundingConsumer.requestRandomWords();
        vm.stopPrank();
    }
}

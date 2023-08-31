// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VRFDirectFundingConsumer
 * @notice A smart contract that utilizes Chainlink VRF - Direct Funding method and
 * transfers the cost of each VRF call to the end user.
 */
contract VRFDirectFundingConsumer is VRFV2WrapperConsumerBase {
    event RequestSent(uint256 requestId, uint32 numWords);

    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    IERC20 public linkTokenContract;
    VRFV2WrapperInterface public vrfWrapper;
    RequestConfig public requestConfig;
    address public owner;

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    struct RequestConfig {
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    // Array of all request IDs
    uint256[] public requestIds;
    uint256 public lastRequestId;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @param callbackGasLimit The amount of gas to send with the callback
     * @param linkAddress The address of the LINK token
     * @param wrapperAddress The address of the VRFV2Wrapper contract
     * @param requestConfirmations The number of confirmations to wait for
     */
    constructor(
        uint32 callbackGasLimit,
        address linkAddress,
        address wrapperAddress,
        uint16 requestConfirmations
    ) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {
        require(linkAddress != address(0), "Link Token address cannot be 0x0");
        require(wrapperAddress != address(0), "Wrapper address cannot be 0x0");
        owner = msg.sender;
        vrfWrapper = VRFV2WrapperInterface(wrapperAddress);
        linkTokenContract = IERC20(linkAddress);
        requestConfig = RequestConfig({
            callbackGasLimit: callbackGasLimit,
            requestConfirmations: requestConfirmations,
            numWords: 1
        });
    }

    /**
     * @dev Sends a VRF request and transfers the cost of the request to the contract
     * @return requestId The ID of the VRF request
     */
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Calculate the amount of LINK to send with the request
        uint256 requestPrice = vrfWrapper.calculateRequestPrice(
            requestConfig.callbackGasLimit
        );
        // Transfer the LINK to the VRF Wrapper contract
        // The VRF Wrapper contract will transfer the LINK to the VRF Coordinator
        require(
            linkTokenContract.transferFrom(
                msg.sender,
                address(this),
                requestPrice
            ),
            "Not enough LINK"
        );
        // Send the request to the VRF Wrapper contract
        requestId = requestRandomness(
            requestConfig.callbackGasLimit,
            requestConfig.requestConfirmations,
            requestConfig.numWords
        );
        // Update the request status in the mapping
        s_requests[requestId] = RequestStatus({
            paid: requestPrice,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, requestConfig.numWords);
        return requestId;
    }

    /**
     * @dev Fulfills a VRF request by updating the request status in the mapping
     * @param _requestId The ID of the VRF request to fulfill
     * @param _randomWords The array of random words generated by the VRF request
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    /**
     * @dev Retrieves the status of a VRF request
     * @param _requestId The ID of the VRF request
     * @return paid The cost of the VRF request
     * @return fulfilled Whether or not the VRF request has been fulfilled
     * @return randomWords The array of random words generated by the VRF request
     */
    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }
}

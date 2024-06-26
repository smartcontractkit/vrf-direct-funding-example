// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title VRFDirectFundingConsumer
 * @notice A smart contract that utilizes Chainlink VRF - Direct Funding method and
 * transfers the cost of each VRF call to the end user.
 */
contract VRFDirectFundingConsumer is VRFV2PlusWrapperConsumerBase, ConfirmedOwner {
    error VRFDirectFundingConsumer__AddressCannotBe0();
    error VRFDirectFundingConsumer__NotEnoughLINK();
    error VRFDirectFundingConsumer__InsufficientAllowance();
    error VRFDirectFundingConsumer__LINKTransferFailed();

    RequestConfig public requestConfig;

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

    event TokensTransferred(address from, address to, uint256 amount);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    /**
     * @param callbackGasLimit The amount of gas to send with the callback
     * @param wrapperAddress The address of the VRFV2Wrapper contract
     * @param requestConfirmations The number of confirmations to wait for
     */
    constructor(uint32 callbackGasLimit, address wrapperAddress, uint16 requestConfirmations)
        VRFV2PlusWrapperConsumerBase(wrapperAddress)
        ConfirmedOwner(msg.sender)
    {
        if (wrapperAddress == address(0)) revert VRFDirectFundingConsumer__AddressCannotBe0();

        requestConfig =
            RequestConfig({callbackGasLimit: callbackGasLimit, requestConfirmations: requestConfirmations, numWords: 1});
    }

    /**
     * @dev Initiates a randomness request and transfers the necessary LINK tokens from the user to pay for the service.
     * This function first calculates the price for the randomness request, transfers the required LINK tokens from the caller's address to this contract,
     * and then submits the randomness request to the VRF Wrapper contract. It handles all associated state updates and emits relevant events.
     * @notice The caller must have sufficient LINK tokens to cover the cost of the request and must have approved this contract to spend the necessary amount.
     * On successful execution, emits a `TokensTransferred` event for the LINK payment and a `RequestSent` event for the VRF request.
     * @return requestId The unique identifier for the submitted VRF request.
     */
    function requestRandomWords() external returns (uint256) {
        // Calculate the price required for the VRF request based on the configured parameters.
        uint256 requestPrice = calculateRequestPrice();

        // Transfer the required LINK tokens from the caller's address to this contract.
        transferLinkFromUser(requestPrice);

        // Send the randomness request to the VRF Wrapper contract and retrieve the request ID and the paid price.
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}));
        (uint256 requestId, uint256 reqPrice) = requestRandomness(
            requestConfig.callbackGasLimit, requestConfig.requestConfirmations, requestConfig.numWords, extraArgs
        );
        // Record the request details.
        s_requests[requestId] = RequestStatus({paid: reqPrice, randomWords: new uint256[](0), fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;

        // Emit an event indicating that a request has been sent.
        emit RequestSent(requestId, requestConfig.numWords);

        return requestId;
    }

    /**
     * @dev Retrieves the status of a VRF request
     * @param _requestId The ID of the VRF request
     * @return paid The cost of the VRF request
     * @return fulfilled Whether or not the VRF request has been fulfilled
     * @return randomWords The array of random words generated by the VRF request
     */
    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * @dev Fulfills a VRF request by updating the request status in the mapping.
     * @param _requestId The ID of the VRF request to fulfill.
     * @param _randomWords The array of random words generated by the VRF request.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }

    /**
     * @dev Calculates and returns the price required for a VRF request based on the configured gas limit and number of words requested.
     * @return price The cost in LINK tokens for the VRF request, derived from the current configuration settings of the contract.
     */
    function calculateRequestPrice() internal view returns (uint256) {
        return i_vrfV2PlusWrapper.calculateRequestPrice(requestConfig.callbackGasLimit, requestConfig.numWords);
    }

    /**
     * @notice Transfers a specified amount of LINK tokens from the caller's account to this contract.
     * @dev Before calling this function, the caller must ensure that they have approved this contract to spend the necessary amount of LINK tokens on their behalf.
     * The function checks that the caller's balance and allowance are sufficient to cover the `requestPrice` and will revert if any condition is not met.
     * @param requestPrice The amount of LINK to be transferred from the caller to the contract.
     */
    function transferLinkFromUser(uint256 requestPrice) internal {
        // Check if the sender has enough LINK tokens
        if (i_linkToken.balanceOf(msg.sender) < requestPrice) revert VRFDirectFundingConsumer__NotEnoughLINK();

        // Check if the allowance is sufficient to perform the transfer
        uint256 currentAllowance = i_linkToken.allowance(msg.sender, address(this));
        if (currentAllowance < requestPrice) revert VRFDirectFundingConsumer__InsufficientAllowance();

        // Attempt to transfer LINK tokens from the sender to this contract
        if (!i_linkToken.transferFrom(msg.sender, address(this), requestPrice)) {
            revert VRFDirectFundingConsumer__LINKTransferFailed();
        }

        // Emit an event indicating the successful transfer
        emit TokensTransferred(msg.sender, address(this), requestPrice);
    }

    /**
     * @notice Withdraws all LINK tokens held by the contract and sends them to the contract owner.
     * This function is restricted to the contract owner.
     */
    function withdrawLink() public onlyOwner {
        if (!i_linkToken.transferFrom(address(this), msg.sender, i_linkToken.balanceOf(address(this)))) {
            revert VRFDirectFundingConsumer__LINKTransferFailed();
        }
    }
}

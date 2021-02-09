pragma solidity >=0.5.0 <0.7.0;

import "./provable/Provable.sol";

contract InstructionOracle is usingProvable {
    string public response;
    string public request;
    string dataSource = "IPFS";
    event LogConstructorInitiated(string nextStep);
    event LogDataUpdated(string price);
    event LogNewProvableQuery(string description);

    // address public owner;
    uint gasLimit = 200000;

    function __callback(bytes32 myid, string memory result) public {
        if (msg.sender != provable_cbAddress()) revert();
        response = result;
        emit LogDataUpdated(result);
    }

    function changeSource(string memory _str) public {
        request = _str;
    }

    function setCustomGasLimit(uint _gas) public {
        // TO CONFIRM:- WHO CAN SET GAS LIMIT ?
        // require(msg.sender == owner, "Unauthorized");
        gasLimit = _gas;
    }

    function update() public payable {
        if (provable_getPrice(dataSource) > address(this).balance) {
            emit LogNewProvableQuery(
                "Provable query was NOT sent, please add some ETH to cover for the query fee"
            );
        } else {
            emit LogNewProvableQuery(
                "Provable query was sent, standing by for the answer.."
            );
            provable_query(dataSource, request, gasLimit);
        }
    }
}

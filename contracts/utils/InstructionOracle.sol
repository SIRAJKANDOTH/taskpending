pragma solidity >=0.5.0 <0.7.0;

import "./provable/Provable.sol";

contract InstructionOracle is usingProvable {
    event LogConstructorInitiated(string nextStep);
    event LogDataUpdated(string price);
    event LogNewProvableQuery(string description);

    //    function ExampleContract() payable {
    //        LogConstructorInitiated("Constructor was initiated. Call 'updatePrice()' to send the Provable Query.");
    //    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != provable_cbAddress()) revert();
        response = result;
        LogDataUpdated(result);
    }

    //   json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price

    function changeSource(string _str) public {
        request = _str;
    }

    function update() payable {
        if (provable_getPrice("URL") > this.balance) {
            LogNewProvableQuery(
                "Provable query was NOT sent, please add some ETH to cover for the query fee"
            );
        } else {
            LogNewProvableQuery(
                "Provable query was sent, standing by for the answer.."
            );
            provable_query("URL", request);
        }
    }
}

pragma solidity ^0.5.3;
import "./GnosisSafeProxy.sol";
import "./IProxyCreationCallback.sol";
import "../interfaces/IAPContract.sol";

contract GnosisSafeProxyFactory {

    address private MasterCopy;
    address private APSContract;

    event ProxyCreation(GnosisSafeProxy proxy , address MasterCopy);

    constructor(address _MasterCopy, address _APSContract) public {
    MasterCopy = _MasterCopy;
    APSContract = _APSContract;
    }


    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(bytes memory data)
        public
        returns (GnosisSafeProxy proxy)
    {
        proxy = new GnosisSafeProxy(MasterCopy);
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
        emit ProxyCreation(proxy, MasterCopy);
        IAPContract(APSContract).createVault(address(proxy));

    }

}

pragma solidity >=0.5.0 <0.7.0;
import "../../../interfaces/IAPContract.sol";

contract LockStorage {
    struct WithdrawalStorage {
        address[] requestedAddresses;
        address[] withdrawalAsset; // addresses of requested
        uint256[] amounts; // safe share
    }
    mapping(address => WithdrawalStorage) vaultWithdrawalRequests;
    address private APContract;

    constructor(address _APContract) public {
        APContract = _APContract;
    }

    function addRequest(
        address _withdrawer,
        address _asset,
        uint256 _amount
    ) external {
        require(
            IAPContract(APContract).isVault(msg.sender),
            "Not a registered vault!"
        );
        vaultWithdrawalRequests[msg.sender].requestedAddresses.push(
            _withdrawer
        );
        vaultWithdrawalRequests[msg.sender].withdrawalAsset.push(_asset);
        vaultWithdrawalRequests[msg.sender].amounts.push(_amount);
    }

    function clearWithdrawals() external {
        require(
            IAPContract(APContract).isVault(msg.sender),
            "Not a registered vault!"
        );
        vaultWithdrawalRequests[msg.sender] = WithdrawalStorage(
            new address[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    function getWithdrawalList(address _vaultAddress)
        external
        view
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        return (
            vaultWithdrawalRequests[_vaultAddress].requestedAddresses,
            vaultWithdrawalRequests[_vaultAddress].withdrawalAsset,
            vaultWithdrawalRequests[_vaultAddress].amounts
        );
    }
}

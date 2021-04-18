pragma solidity >=0.5.0 <0.7.0;
import "../../../interfaces/IAPContract.sol";

contract LockStorage {

    struct WithdrawlStorage {
        address[] requestedAddresses;
        address[] withdrawalAsset; // addresses of requested
        uint256[] amounts; // safe share
    }
    mapping(address => WithdrawlStorage) vaultWithdrawalRequests;
    address private APContract;


    constructor(address _APContract) 
        public
    {
        APContract=_APContract;
    }

    function addRequest(address _withdrawer,address _asset, uint256 _amount) 
        external
    {
        require(IAPContract(APContract).isVault(msg.sender),"Not a registered vault!");
        vaultWithdrawalRequests[msg.sender].requestedAddresses.push(_withdrawer);
        vaultWithdrawalRequests[msg.sender].withdrawalAsset.push(_asset);
        vaultWithdrawalRequests[msg.sender].amounts.push(_amount);
    }

    function clearWithdrawals() 
        external
    {
        require(IAPContract(APContract).isVault(msg.sender),"Not a registered vault!");
        vaultWithdrawalRequests[msg.sender] = WithdrawlStorage( new address[](0), new address[](0), new uint256[](0));
    }

    function getWithdrawalList() 
        external 
        view 
        returns(address[] memory,address[] memory,uint256[] memory)
    {
        return(vaultWithdrawalRequests[msg.sender].requestedAddresses,vaultWithdrawalRequests[msg.sender].withdrawalAsset,vaultWithdrawalRequests[msg.sender].amounts);
    }
}
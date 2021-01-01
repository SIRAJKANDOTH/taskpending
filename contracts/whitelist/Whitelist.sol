pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/utils/Address.sol";



contract Whitelist{
    using Address for address;

    struct Role{
        // address[] vault;
        address[] members;
        //add-remove-block web3 interface
        address admin;
        address owner;
        bool created;
    }
    address public whiteListManager;
    mapping(string=>Role) private whiteList;

    modifier onlyOwner{
         require(msg.sender == whiteListManager,"Only Whitelist manager can call this function.");
        _;
    }


    function _isRole(string memory _name) private view returns(bool){
        return whiteList[_name].created;
    }


    function createRole(string memory _name, address _admin) public onlyOwner{
        address[] memory members;
        Role memory newRole= Role(members,_admin,msg.sender,true);
        whiteList[_name]=newRole;
    }

    function addMembersToRole(string memory _roleName,address memberAddress) public{
        require(_isRole(_roleName),"Role doesn't exist!");
        whiteList[_roleName].members.push(memberAddress);
    }

    function removeMembersFromRole(string memory _roleName,address memberAddress) public view{
        require(_isRole(_roleName),"Role doesn't exist!");
        // whiteList[_roleName].members.push(memberAddress);
        // delete whiteList[_roleName].members[index];
    }

    


// methods



}
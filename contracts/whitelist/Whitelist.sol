pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/utils/Address.sol";



contract Whitelist{
    using Address for address;

    struct Role{
        // address[] vault;
        mapping(address=>bool) members;
        address admin;
        address owner;
        bool created;
    }
    address public whiteListManager;
    mapping(string=>Role) private whiteList;
    mapping(address=>mapping(string=>bool)) private memberRoles;

    modifier onlyOwner{
         require(msg.sender == whiteListManager,"Only Whitelist manager can call this function.");
        _;
    }


    function _isRole(string memory _name) private view returns(bool){
        return whiteList[_name].created;
    }

    constructor() public{
        whiteListManager=msg.sender;

         Role memory newRole= Role({admin:msg.sender,owner:msg.sender,created:true});
        whiteList["GROUPA"]=newRole;
        whiteList["GROUPA"].members[msg.sender]=true;



        newRole= Role({admin:msg.sender,owner:msg.sender,created:true});
        whiteList["GROUPB"]=newRole;
        whiteList["GROUPB"].members[msg.sender]=true;


        memberRoles[msg.sender]["GROUPA"]=true;
        memberRoles[msg.sender]["GROUPB"]=true;
    }

    // function _isNotMemeber(address _address,string memory _role) private view returns(bool){
    //     return memberRoles[_address].contains[_role];
    // }


    function createRole(string memory _name, address _admin) public onlyOwner{
        require(!_isRole(_name),"Role already exist!");
        Role memory newRole= Role({admin:_admin,owner:msg.sender,created:true});
        whiteList[_name]=newRole;
        whiteList[_name].members[_admin]=true;
        whiteList[_name].members[msg.sender]=true;
    }

    function deleteRole(string memory _roleName) public onlyOwner{
        require(_isRole(_roleName),"Role doesn't exist!");
        delete whiteList[_roleName];

    }

    function _isGroupAdmin(string memory _roleName,address sender) private view returns(bool)
    {
        return whiteList[_roleName].admin==sender;
    }

    function addMembersToRole(string memory _roleName,address memberAddress) public{
        require(_isRole(_roleName),"Role doesn't exist!");
        require(_isGroupAdmin(_roleName,msg.sender),"Only goup admin is permitted for this operation");
        whiteList[_roleName].members[memberAddress]=true;
    }

    function removeMembersFromRole(string memory _roleName,address memberAddress) public{
        require(_isRole(_roleName),"Role doesn't exist!");
        require(_isGroupAdmin(_roleName,msg.sender),"Only goup admin is permitted for this operation");
        delete whiteList[_roleName].members[memberAddress];
    }

    function changeManager(address _manager) public onlyOwner{
        whiteListManager=_manager;
    }

    function isMember(string memory _roleName,address member) public view returns(bool)
    {
        require(_isRole(_roleName),"Role doesn't exist!");
        return memberRoles[member][_roleName];

    }

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/utils/Address.sol";

contract Whitelist
{
    using Address for address;

    struct WhitelistGroup
    {
        mapping(address => bool) members;
        address whitelistGroupAdmin;
        bool created;
    }
    
    uint256 groupId;
    address public whiteListManager;
    mapping(uint256 => WhitelistGroup) private whitelistGroups;

    constructor() public
    {
        whiteListManager=msg.sender;
    }

    modifier onlyWhitelistManager{
        require(msg.sender == whiteListManager, "Only Whitelist manager can call this function.");
        _;
    }

    function changeManager(address _manager) 
        public 
        onlyWhitelistManager
    {
        whiteListManager=_manager;
    }

    function _isGroup(uint256 _groupId) 
        private 
        view 
        returns(bool)
    {
        return whitelistGroups[_groupId].created;
    }

    function _isGroupAdmin(uint256 _groupId) 
        private 
        view 
        returns(bool)
    {
        return whitelistGroups[_groupId].whitelistGroupAdmin == msg.sender;
    }

    function createGroup(address _whitelistGroupAdmin) 
        public
        returns(uint256) 
    {
        groupId += 1;
        require(!whitelistGroups[groupId].created, "Group already exists");
        WhitelistGroup memory newGroup = 
        WhitelistGroup({ whitelistGroupAdmin : _whitelistGroupAdmin, created : true });
        whitelistGroups[groupId] = newGroup;
        whitelistGroups[groupId].members[_whitelistGroupAdmin] = true;
        whitelistGroups[groupId].members[msg.sender] = true;
        return groupId;
    }

    function deleteGroup(uint256 _groupId) 
        public 
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(_isGroupAdmin(_groupId, msg.sender), "Only goup admin is permitted for this operation");
        delete whitelistGroups[_groupId];
    }

    function addMembersToGroup(uint256 _groupId, address _memberAddress) 
        public
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(_isGroupAdmin(_groupId, msg.sender), "Only goup admin is permitted for this operation");
        whitelistGroups[_groupId].members[_memberAddress] = true;
    }

    function removeMembersFromGroup(uint256 _groupId, address _memberAddress) 
        public
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(_isGroupAdmin(_groupId, msg.sender), "Only goup admin is permitted for this operation");
        delete whitelistGroups[_groupId].members[_memberAddress];
    }

    function isMember(uint256 _groupId, address _memberAddress) 
        public 
        view 
        returns(bool)
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        return whitelistGroups[_groupId].members[_memberAddress];
    }

}
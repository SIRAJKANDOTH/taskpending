pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./ChainlinkService.sol";

contract APContract is ChainlinkService{

    struct Asset{
        string name;
        address feedAddress;
        bool created;
        string symbol;
    }

    struct Protocol{
        string name;
        bool created;
        string symbol;
    }

    struct Vault{
        mapping(address => bool) vaultAssets;
        mapping(address => bool) vaultProtocols;
        address vaultAPSManager;
        string[] whitelistGroup;
        bool created;
    }
    event VaultCreation(address vaultAddress);

    mapping(address => Asset) assets;

    mapping(address => Protocol) protocols;

    mapping(address => Vault) vaults;

    mapping(address => address) safeOwner;

    address private MasterCopy;

    address private superAdmin;

    mapping(address => bool) APSManagers;

    address private whitelistModule;


    constructor(address _MasterCopy, address _whitelistModule) public{
        superAdmin = msg.sender;
        APSManagers[msg.sender] = true;
        MasterCopy = _MasterCopy;
        whitelistModule = _whitelistModule;
    }

//APS Managers and Super Admin functions
    modifier onlySuperAdmin
    {
        require(superAdmin == msg.sender, "Only Super Admin is allowed to perform this operation");
        _;
    }

    modifier onlyManager
    {
        require(APSManagers[msg.sender], "Only APS managers allowed to perform this operation!");
        _;
    }

    modifier onlyVault
    {
        require(isVault(msg.sender), "Only Yieldster vaults can perform this operation");
        _;
    }
    modifier onlySafeOwner
    {
        require(safeOwner[msg.sender] == tx.origin, "Only safe Owner can perform this operation");
        _;
    }


    function addManager(address _manager) 
    public
    onlySuperAdmin
    {
        APSManagers[_manager] = true;
    }

    function removeManager(address _manager)
    public
    onlySuperAdmin
    {
        APSManagers[_manager] = false;
    } 


    function createVault() 
        public 
        returns (address result) 
        {
            bytes20 targetBytes = bytes20(MasterCopy);
            assembly {
              let clone := mload(0x40)
              mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
              mstore(add(clone, 0x14), targetBytes)
              mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
              result := create(0, clone, 0x37)
       }
       safeOwner[result] = msg.sender;
       emit VaultCreation(result);
    }

    function isVault(
        address query
        ) 
        internal 
        view 
        returns (bool result) 
        {
            bytes20 targetBytes = bytes20(MasterCopy);
            assembly {
              let clone := mload(0x40)
              mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
              mstore(add(clone, 0xa), targetBytes)
              mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

              let other := add(clone, 0x40)
              extcodecopy(query, other, 0, 0x2d)
              result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
              )
            }
        }

//Vaults

    function addVault(
        address[] memory _vaultAssets,
        address[] memory _vaultProtocols,
        address _vaultAPSManager,
        string[] memory _whitelistGroup
    )
    onlyVault
    onlySafeOwner
    public
    {   
        Vault memory newVault = Vault(
            {
            vaultAPSManager:_vaultAPSManager, 
            whitelistGroup:_whitelistGroup, 
            created:true
            });

        vaults[msg.sender] = newVault;

        for (uint256 i = 0; i < _vaultAssets.length; i++) {
            address asset = _vaultAssets[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
        }

        for (uint256 i = 0; i < _vaultProtocols.length; i++) {
            address protocol = _vaultProtocols[i];
            require(_isProtocolPresent(protocol), "protocol not supported by Yieldster");
            vaults[msg.sender].vaultProtocols[protocol] = true;
        }

    }

    function _isVaultPresent(address _address) external view returns(bool)
    {
        return vaults[_address].created;
    }
    
    function isAssetEnabledInVault(
        address _vaultAddress, 
        address _asset
    )
    external
    view
    returns(bool)
    {
        require(this._isVaultPresent(_vaultAddress),"Vault is not present in APS");
        return vaults[_vaultAddress].vaultAssets[_asset];
    }
    

// Assets
    function _isAssetPresent(address _address) private view returns(bool)
    {
        return assets[_address].created;
    }
    

    function addAsset(
        string memory _symbol, 
        string memory _name,
        address feedAddress,
        address _tokenAddress
        ) 
        public 
        onlyManager
        {
        require(!_isAssetPresent(_tokenAddress),"Asset already present!");
        Asset memory newAsset=Asset({name:_name,feedAddress:feedAddress,created:true,symbol:_symbol});
        assets[_tokenAddress]=newAsset;
    }

    function removeAsset(
        address _tokenAddress
        ) 
        public 
        onlyManager
        {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        delete assets[_tokenAddress];
    }
    
    function getAssetDetails(
        address _tokenAddress
        ) 
        public 
        view 
        returns(string memory, address, string memory)
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        return(assets[_tokenAddress].name,assets[_tokenAddress].feedAddress,assets[_tokenAddress].symbol);

    }

    function getUSDPrice(address _tokenAddress) public returns(int,uint)
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        return getLatestPrice(assets[_tokenAddress].feedAddress);
    }

// Protocols
    function _isProtocolPresent(address _address) private view returns(bool)
    {
        return protocols[_address].created;
    }

    function addProtocol(
        string memory _symbol,
        string memory _name,
        address _protocolAddress
        ) 
        public 
        onlyManager
        {
        require(!_isProtocolPresent(_protocolAddress),"Protocol already present!");
        Protocol memory newAsset=Protocol({name:_name,created:true,symbol:_symbol});
        protocols[_protocolAddress]=newAsset;
    }

    function removeProtocol(address _protocolAddress) public onlyManager{
        require(_isProtocolPresent(_protocolAddress),"Protocol not present!");
        delete protocols[_protocolAddress];
    }

}
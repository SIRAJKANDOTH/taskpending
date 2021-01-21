pragma solidity >=0.5.0 <0.7.0;
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
        uint256[] whitelistGroup;
    }

    mapping(address => Asset) assets;

    mapping(address => Protocol) protocols;

    mapping(address => Vault) vaults;

    address private superAdmin;
    mapping(address => bool) APSManagers;

    address private whitelistModule;


    constructor(address _whitelistModule) public{
        superAdmin = msg.sender;
        APSManagers[msg.sender] = true;
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

//Vaults

    function addVault(
        address vaultAddress,
        address[] memory _vaultAssets,
        address[] memory _vaultProtocols,
        address _vaultAPSManager,
        uint256[] memory _whitelistGroup
    )
    public
    onlyManager
    {
        Vault memory newVault = Vault({vaultAPSManager:_vaultAPSManager, whitelistGroup:_whitelistGroup});
        for (uint256 i = 0; i < _vaultAssets.length; i++) {
            address asset = _vaultAssets[i];
            require(asset != address(0), "Invalid asset provided");
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[vaultAddress] = newVault;
            vaults[vaultAddress].vaultAssets[asset] = true;
        }
        for (uint256 i = 0; i < _vaultProtocols.length; i++) {
            address protocol = _vaultProtocols[i];
            require(protocol != address(0), "Invalid protocol provided");
            require(_isProtocolPresent(protocol), "protocol not supported by Yieldster");
            vaults[vaultAddress] = newVault;
            vaults[vaultAddress].vaultProtocols[protocol] = true;
        }

    }
    



// Assets
    function _isAssetPresent(address _address) private view returns(bool)
    {
        return assets[_address].created;
    }
    
    function isAssetPresent(address _address) external view returns(bool)
    {
        return _isAssetPresent(_address);
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
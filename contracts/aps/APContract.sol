pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
contract APContract is ChainlinkService{

    struct Asset{
        string name;
        address feedAddress;
        bool created;
        string symbol;
        // address tokenAddress;
    }

    struct Protocol{
        string name;
        bool created;
        string symbol;
    }

    // Key will be the -symbol of that partiular coin
    mapping(address=>Asset) assets;
    address private apsManager;


    constructor() public{
        apsManager=msg.sender;
    }

    modifier onlyManager
    {
        require(msg.sender == apsManager, "Only APS manager allowed to call this operation!");
        _;
    }

    function _isAssetPresent(address _address)private view returns(bool)
    {
        return assets[_address].created;
    }


    function addAsset(string memory _symbol,string memory _name,address feedAddress,address _tokenAddress) public onlyManager{
        require(!_isAssetPresent(_tokenAddress),"Asset already present!");
        Asset memory newAsset=Asset({name:_name,feedAddress:feedAddress,created:true,symbol:_symbol});
        assets[_tokenAddress]=newAsset;
    }

    function removeAsset(address _tokenAddress) public onlyManager{
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        delete assets[_tokenAddress];
    }
    
    function getAssetDetails(address _tokenAddress) public view returns(string memory,address ,string memory)
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        return(assets[_tokenAddress].name,assets[_tokenAddress].feedAddress,assets[_tokenAddress].symbol);

    }

    function getUSDPrice(address _tokenAddress) public returns(int,uint)
    {
        require(_isAssetPresent(_tokenAddress),"Asset not present!");
        return getLatestPrice(assets[_tokenAddress].feedAddress);
    }

}
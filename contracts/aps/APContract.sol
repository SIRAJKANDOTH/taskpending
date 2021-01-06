pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
contract APContract is ChainlinkService{

    struct Asset{
        string name;
        address feedAddress;
        bool created;
    }

    // Key will be the -symbol of that partiular coin
    mapping(string=>Asset) assets;
    address private apsManager;


    constructor() public{
        apsManager=msg.sender;
    }

    modifier onlyManager
    {
        require(msg.sender == apsManager, "Only APS manager allowed to call this operation!");
        _;
    }

    function _isAssetPresent(string memory _symbol)private view returns(bool)
    {
        return assets[_symbol].created;
    }


    function addAsset(string memory _symbol,string memory _name,address feedAddress) public onlyManager{
        require(!_isAssetPresent(_symbol),"Asset already present!");
        Asset memory newAsset=Asset({name:_name,feedAddress:feedAddress,created:true});
        assets[_symbol]=newAsset;
    }

    function removeAsset(string memory _symbol) public onlyManager{
        require(_isAssetPresent(_symbol),"Asset not present!");
        delete assets[_symbol];
    }

    function getUSDPrice(string memory _symbol) public returns(int)
    {
        require(_isAssetPresent(_symbol),"Asset not present!");
        return getLatestPrice(assets[_symbol].feedAddress);
    }

}
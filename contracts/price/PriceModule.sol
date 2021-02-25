// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";


contract PriceModule is ChainlinkService
{
    mapping (address => address) feedAddress;

    address public priceModuleManager;
    address public APContract;

    constructor(address _APContract)
    public
    {
        priceModuleManager = msg.sender;
        APContract = _APContract;
    }

    modifier onlyAPS{
         require(msg.sender == APContract,"Only APS can call this function.");
        _;
    }

    function setFeedAddress (address _tokenAddress, address _feedAddress)
        public
        onlyAPS
    {
        feedAddress[_tokenAddress] = _feedAddress;
    }

    // function getUSDPrice(address _tokenAddress) 
    //     public 
    //     view
    //     returns(int, uint, uint8)
    // {
    //     require(feedAddress[_tokenAddress] != address(0), "This asset price is not present");
    //     return getLatestPrice(feedAddress[_tokenAddress]);
    // }

    // Use this function in testing environment other than rinkeby

    function getUSDPrice(address _tokenAddress) 
        public view
        returns(int, uint, uint8)
    {
        if(_tokenAddress == 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa)
        return(100173255,1612935434,8);
        else if(_tokenAddress == 0x01BE23585060835E02B77ef475b0Cc51aA1e0709)
        return(2447000000,1612762790,8);
        else if(_tokenAddress == 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b)
        return(100000000,1612935389,8);
        else if(_tokenAddress == 0xbF7A7169562078c96f0eC1A8aFD6aE50f12e5A99)
        return(43465888,1612935374,8);
        else if(_tokenAddress == 0x030b0a08eCaDdE5Ac33859a48d87416946C966A1)
        return(12932580607,1612935494,8);
        else if(_tokenAddress == 0xd729A77e319E059B4467C402e173c552E63A6c55)
        return(23195708,1612934474,8);
        return(2447580000,1612762790,8);
    }
}
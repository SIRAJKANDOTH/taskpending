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

    function getUSDPrice(address _tokenAddress) 
        public 
        view
        returns(int, uint, uint8)
    {
        return getLatestPrice(feedAddress[_tokenAddress]);
    }
}
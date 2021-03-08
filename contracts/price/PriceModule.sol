// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
import "../external/GnosisSafeMath.sol";


contract PriceModule is ChainlinkService
{

    using GnosisSafeMath for uint256;
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
        returns(uint256)
    {
        require(feedAddress[_tokenAddress] != address(0), "This asset price is not present");
        (int price, uint timestamp, uint8 decimals) = getLatestPrice(feedAddress[_tokenAddress]);

       if(decimals < 18)
        {
            return (uint256(price)).mul(10 ** uint256(18 - decimals));
        }
        else if (decimals > 18)
        {
            return (uint256(price)).div(uint256(decimals - 18));
        }
        else 
        {
            return uint256(price);
        }
    }

    // Use this function in testing environment other than rinkeby

    // function getUSDPrice(address _tokenAddress) 
    //     public 
    //     view
    //     returns(uint256)
    // {
    //     int price;
    //     uint8 decimals;

    //     if(_tokenAddress == 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa)
    //     {
    //         price = 100173255;
    //         decimals = 8;
    //     }
    //     else if(_tokenAddress == 0x01BE23585060835E02B77ef475b0Cc51aA1e0709)
    //     {
    //         price = 2447000000;
    //         decimals = 8;
    //     }
    //     else if(_tokenAddress == 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b)
    //     {
    //         price = 100000000;
    //         decimals = 8;
    //     }
    //     else if(_tokenAddress == 0xbF7A7169562078c96f0eC1A8aFD6aE50f12e5A99)
    //     {
    //         price = 43465888;
    //         decimals = 8;
    //     }
    //     else if(_tokenAddress == 0x030b0a08eCaDdE5Ac33859a48d87416946C966A1)
    //     {
    //         price = 12932580607;
    //         decimals = 8;
    //     }
    //     else if(_tokenAddress == 0xd729A77e319E059B4467C402e173c552E63A6c55)
    //     {
    //         price = 23195708;
    //         decimals = 8;
    //     }
    //     else
    //     {
    //         price = 2447580000;
    //         decimals = 8;
    //     }
    //     if(decimals < 18)
    //     {
    //         return (uint256(price)).mul(10 ** uint256(18 - decimals));
    //     }
    //     else if (decimals > 18)
    //     {
    //         return (uint256(price)).div(uint256(decimals - 18));
    //     }
    //     else 
    //     {
    //         return uint256(price);
    //     }
    // }
}
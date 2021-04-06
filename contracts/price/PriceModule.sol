// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
import "../external/YieldsterVaultMath.sol";
import "../interfaces/IRegistry.sol";


contract PriceModule is ChainlinkService
{

    using YieldsterVaultMath for uint256;
    
    address public priceModuleManager;
    
    address public APContract;

    address public curveRegistry;

    struct ChainlinkToken {
        address feedAddress;
        bool created;
    }

    struct CurveToken {
        bool created;
    }

    mapping (address => address) feedAddress;
    mapping(address => ChainlinkToken) chainlinkTokens;
    mapping(address => CurveToken) curveTokens;

    constructor(address _APContract, address _curveRegistry)
    public
    {
        priceModuleManager = msg.sender;
        APContract = _APContract;
        curveRegistry = _curveRegistry;
    }

    modifier onlyAPS{
         require(msg.sender == APContract,"Only APS can call this function.");
        _;
    }

    function setCurveRegistry(address _curveRegistry)
        public
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveRegistry = _curveRegistry;
    }

    function setFeedAddress (address _tokenAddress, address _feedAddress)
        public
        onlyAPS
    {
        feedAddress[_tokenAddress] = _feedAddress;
    }

    function addChainlinkToken(address _tokenAddress, address _feedAddress)
        public
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        ChainlinkToken memory newChainlinkToken = ChainlinkToken({ feedAddress:_feedAddress, created:true});
        chainlinkTokens[_tokenAddress] = newChainlinkToken;
    }

    function addCurveToken(address _tokenAddress)
        public
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        CurveToken memory newCurveToken = CurveToken({created:true});
        curveTokens[_tokenAddress] = newCurveToken;
    }


    function getUSDPrice(address _tokenAddress) 
        public 
        view
        returns(uint256)
    {
        if(chainlinkTokens[_tokenAddress].created) {
            (int price, , uint8 decimals) = getLatestPrice(feedAddress[_tokenAddress]);

            if(decimals < 18) {
                return (uint256(price)).mul(10 ** uint256(18 - decimals));
            }
            else if (decimals > 18) {
                return (uint256(price)).div(uint256(decimals - 18));
            }
            else {
                return uint256(price);
            }
        } else if(curveTokens[_tokenAddress].created) {
            return IRegistry(curveRegistry).get_virtual_price_from_lp_token(_tokenAddress);
        } else {
            revert("Token not present");
        }
    }


    // function getUSDPrice(address _tokenAddress)  
    //     public 
    //     view
    //     returns(uint256)
    // {
    //     require(feedAddress[_tokenAddress] != address(0), "This asset price is not present");
    //     (int price, , uint8 decimals) = getLatestPrice(feedAddress[_tokenAddress]);

    //    if(decimals < 18)
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
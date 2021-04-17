// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
import "../external/YieldsterVaultMath.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IYieldsterVault.sol";
import "../interfaces/IYieldsterStrategy.sol";


contract PriceModule is ChainlinkService
{

    using YieldsterVaultMath for uint256;
    
    address public priceModuleManager;
    
    address public curveRegistry;

    struct Token {
        address feedAddress;
        uint256 tokenType;
        bool created;
    }

    mapping(address => Token) tokens;

    constructor(address _curveRegistry)
    public
    {
        priceModuleManager = msg.sender;
        curveRegistry = _curveRegistry;
    }

    function setManager(address _manager)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        priceModuleManager = _manager;
    }

    function addToken(
        address _tokenAddress, 
        address _feedAddress, 
        uint256 _tokenType
    )
    external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        Token memory newToken = Token({ feedAddress:_feedAddress, tokenType: _tokenType, created:true});
        tokens[_tokenAddress] = newToken;
    }

    function setCurveRegistry(address _curveRegistry)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveRegistry = _curveRegistry;
    }


    function getUSDPrice(address _tokenAddress) 
        public 
        view
        returns(uint256)
    {
        require(tokens[_tokenAddress].created, "Token not present");

        if(tokens[_tokenAddress].tokenType == 1) {
            (int price, , uint8 decimals) = getLatestPrice(tokens[_tokenAddress].feedAddress);

            if(decimals < 18) {
                return (uint256(price)).mul(10 ** uint256(18 - decimals));
            }
            else if (decimals > 18) {
                return (uint256(price)).div(uint256(decimals - 18));
            }
            else {
                return uint256(price);
            }

        } else if(tokens[_tokenAddress].tokenType == 2) {
            return IRegistry(curveRegistry).get_virtual_price_from_lp_token(_tokenAddress);

        } else if(tokens[_tokenAddress].tokenType == 3) {
            address token = IVault(_tokenAddress).token();
            uint256 tokenPrice = getUSDPrice(token);
            return (tokenPrice.mul(IVault(_tokenAddress).getPricePerFullShare())).div(1e18);

        } else if(tokens[_tokenAddress].tokenType == 4) {
            return IYieldsterStrategy(_tokenAddress).tokenValueInUSD();

        } else if(tokens[_tokenAddress].tokenType == 5) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();

        } else {
            revert("Token not present");
        }
    }

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
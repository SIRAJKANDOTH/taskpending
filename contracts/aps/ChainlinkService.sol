pragma solidity >=0.5.0 <0.7.0;
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";
contract ChainlinkService{
   
    

    /**
     * Network: Rinkby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

    /**
     * Returns the latest price
     */

     // Feed address - https://docs.chain.link/docs/ethereum-addresses
     
    function getLatestPrice(address feedAddress) public view returns (int,uint) {
         AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        (
            ,int price,,uint timeStamp,
        ) = priceFeed.latestRoundData();
        return (price,timeStamp);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../storage/VaultStorage.sol";

contract Exchange
    is 
    VaultStorage
{

    /// @dev Function to exchange tokens to for a target token.
    /// @param _targetToken Address of the target token.
    /// @param _amount Amount of target tokens required.
    function exchangeToken(address _targetToken, uint256 _amount)
        public
        returns(uint256)
    {
        for(uint256 i = 0; i < assetList.length; i++ ){
            uint256 targetTokenUSD = IAPContract(APContract).getUSDPrice(_targetToken);
            uint256 haveTokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);

            if((tokenBalances.getTokenBalance(assetList[i]).mul(uint256(haveTokenUSD))).div(1e18) > (_amount.mul(uint256(targetTokenUSD))).div(1e18)){
                (uint256 returnAmount, uint256[] memory distribution) = 
                IExchange(oneInch).getExpectedReturn(assetList[i], _targetToken, _amount, 0, 0);
                uint256 adjustedAmount = _amount + (_amount - returnAmount).mul(3);

                if( (tokenBalances.getTokenBalance(assetList[i]).mul(uint256(haveTokenUSD))).div(1e18) > (adjustedAmount.mul(uint256(targetTokenUSD))).div(1e18)){
                    (uint256 newReturnAmount, uint256[] memory newDistribution) = 
                    IExchange(oneInch).getExpectedReturn(assetList[i], _targetToken, adjustedAmount, 0, 0);
                    IExchange(oneInch).swap(assetList[i], _targetToken, adjustedAmount, _amount, newDistribution, 0);
                    return newReturnAmount;
                }
            }                
        }
    }

}
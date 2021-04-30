// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../storage/VaultStorage.sol";

contract SafeUtils
    is 
    VaultStorage
{
    /// @dev Function to cleanup vault unsupported tokens to the Yieldster Treasury.
    /// @param cleanUpList List of unsupported tokens to be transfered.
    function safeCleanUp(address[] memory cleanUpList)
        public
    {
        for (uint256 i = 0; i < cleanUpList.length; i++){
            if(! (IAPContract(APContract)._isVaultAsset(cleanUpList[i]))) {
                uint256 _amount = IERC20(cleanUpList[i]).balanceOf(address(this));
                if(_amount > 0) {
                    IERC20(cleanUpList[i]).transfer(IAPContract(APContract).yieldsterTreasury(), _amount);
                }
            }
        }
    }

    function approvedAssetCleanUp(address[] memory _assetList,uint256[] memory _amount,address[] memory reciever) public {
        for (uint256 i = 0; i < _assetList.length; i++) {
             if((IAPContract(APContract)._isVaultAsset(_assetList[i]))) {
                uint256 unmintedShare=IERC20(_assetList[i]).balanceOf(address(this)).sub(tokenBalances.getTokenBalance(_assetList[i]));
                if(unmintedShare>=_amount[i]) {
                   uint256 tokensToBeMinted=getMintValue(getDepositNAV(_assetList[i],_amount[i]));
                   _mint(reciever[i], tokensToBeMinted);
                   tokenBalances.setTokenBalance(_assetList[i],tokenBalances.getTokenBalance(_assetList[i]).add(_amount[i]));
                }
             }
             if(!isAssetDeposited[_assetList[i]])
            {
                isAssetDeposited[_assetList[i]] = true;
                assetList.push(_assetList[i]);
            }
        } 
    }

    function addToAssetList(address[] memory _assetList) public {
        for (uint256 i = 0; i < _assetList.length; i++) {

            if(!isAssetDeposited[_assetList[i]])
            {
                isAssetDeposited[_assetList[i]] = true;
                assetList.push(_assetList[i]);
            }
        }
    }

    function tokenBalanceUpdation(address[] memory _assetList,uint256[] memory _amount) public
    {
        for (uint256 i = 0; i < _assetList.length; i++) {
            tokenBalances.setTokenBalance(_assetList[i],_amount[i]);
        }
    }

}
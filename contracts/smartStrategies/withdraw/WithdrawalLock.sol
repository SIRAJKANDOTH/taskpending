// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../../storage/VaultStorage.sol";
import "./storage/LockStorage.sol";

contract LockedWithdraw
    is 
    VaultStorage
{

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        public
    {
        LockStorage lockStorage= LockStorage(address(0));
        lockStorage.addRequest(msg.sender,_tokenAddress,_shares);
    }

     /// @dev Function to Withdraw shares from the Vault.
    /// @param _shares Amount of Vault token shares.
    function withdraw(uint256 _shares)
        public
    {
         LockStorage lockStorage= LockStorage(address(0));
        lockStorage.addRequest(msg.sender,address(0),_shares);
    }

    function withdrawalCleanUp() public{
        LockStorage lockStorage= LockStorage(address(0));
        (address[] memory withdrawers,address[] memory assets,uint256[] memory amounts)=lockStorage.getWithdrawalList();
        for(uint256 i=0;i<withdrawers.length;i++){
            if(withdrawers[i]!=address(0)&&amounts[i]>0)
            {
                // withdrawal logic
            }
        }
        lockStorage.clearWithdrawals();
    }

}
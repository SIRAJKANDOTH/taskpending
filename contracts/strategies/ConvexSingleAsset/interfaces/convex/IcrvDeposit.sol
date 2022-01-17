pragma solidity ^0.5.0;

interface IcrvDeposit {

    //params are for lock and stakeaddress, if no staking address should be address(0)
    function depositAll(bool , address _stakeAddress) external;
}
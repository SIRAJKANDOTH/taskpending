pragma solidity ^0.5.0;

interface ICVXRewards{
    function balanceOf(address _account) external view returns(uint256);
    function stake(uint256 _amount) external returns(bool);
    function earned(address) external view returns (uint256);
    function getReward(bool) external returns (bool);
}
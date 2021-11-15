pragma solidity ^0.5.0;

interface IRewards{
    function balanceOf(address _account) external view returns(uint256);
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    function withdrawAll(bool _claim) external;
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    function getReward() external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function stakeFor(address _account,uint256 _amount) external returns(bool);
}
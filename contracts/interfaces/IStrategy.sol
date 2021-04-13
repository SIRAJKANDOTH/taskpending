
pragma solidity >=0.5.0 <0.7.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit(address, uint256) external;

    function withdraw(uint256, address) external returns(address, uint256);

    function withdrawAll() external ;

    function balanceOf(address) external view returns (uint256);

    function getStrategyNAV() external view  returns (uint256);

    function changeProtocol(address) external;

    function withdrawAllToSafe() external;

    function tokenValueInUSD() external view returns(uint256);

    function registerSafe() external;

    function deRegisterSafe() external;

    function getActiveProtocol(address) external view returns(address);
    
    function strategyExecutor() external view returns(address);

}

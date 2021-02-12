
pragma solidity >=0.5.0 <0.7.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit(uint256) external;

    // Withdraw to strategy
    function withdraw(address) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    function skim() external;

    // withdrw to strategy
    function withdrawAll() external ;

    function balanceOf() external view returns (uint256);

    function changeProtocol(address) external;
    function withdrawAllToSafe() external;
    function setSafeActiveProtocol(address ) external;
}

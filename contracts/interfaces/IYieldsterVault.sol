pragma solidity >=0.5.0 <0.7.0;

interface IYieldsterVault {
    function tokenValueInUSD() external view returns (uint256);

    function earn(
        address[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external;
}

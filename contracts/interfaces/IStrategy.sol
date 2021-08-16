pragma solidity >=0.5.0 <0.7.0;

interface IStrategy {
    function deposit(
        address[] calldata,
        uint256[] calldata,
        bytes calldata
    ) payable external;

    function withdraw(uint256, address)
        external
        returns (
            bool,
            address,
            uint256
        );

    function balanceOf(address) external view returns (uint256);

    function getStrategyNAV() external view returns (uint256);

    function withdrawAllToSafe(address)
        external
        returns (
            bool,
            address,
            uint256
        );

    function tokenValueInUSD() external view returns (uint256);

    function registerSafe() external;

    function deRegisterSafe() external;

    function getActiveProtocol(address) external view returns (address);

    function strategyExecutor() external view returns (address);
}

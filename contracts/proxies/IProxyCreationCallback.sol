pragma solidity ^0.5.3;
import "./YieldsterVaultProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        YieldsterVaultProxy proxy,
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}

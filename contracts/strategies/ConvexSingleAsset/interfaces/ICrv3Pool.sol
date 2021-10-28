// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrv3Pool {
    function add_liquidity(uint256[3] calldata, uint256) external;

    function get_virtual_price() external returns (uint256);
}

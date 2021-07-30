// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface ICrv3Pool {
    function add_liquidity(uint256[3] calldata, uint256) external;

    function get_virtual_price() external returns (uint256);
}

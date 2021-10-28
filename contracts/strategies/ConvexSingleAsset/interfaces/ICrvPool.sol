// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvPool {
    function add_liquidity(uint256[2] calldata, uint256) external;

    function get_virtual_price() external returns (uint256);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvRegistry {
    function get_pool_from_lp_token(address) external view returns (address);

    function get_lp_token(address) external view returns (address);

    function get_n_coins(address) external view returns (uint256[2] calldata);

    function get_coins(address) external view returns (address[8] calldata);

    function get_virtual_price_from_lp_token(address)
        external
        view
        returns (uint256);
}

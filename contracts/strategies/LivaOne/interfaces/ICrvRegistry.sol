// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface ICrvRegistry {
    function get_pool_from_lp_token(address) external view returns (address);

    function get_lp_token(address) external view returns (address);

    function get_n_coins(address) external view returns (uint256[2] memory);

    function get_coins(address) external view returns (address[8] memory);

    function get_virtual_price_from_lp_token(address)
        external
        view
        returns (uint256);
}

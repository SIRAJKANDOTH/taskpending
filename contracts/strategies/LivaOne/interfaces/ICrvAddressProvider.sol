// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface ICrvAddressProvider {
    function get_registry() external view returns (address);
}

pragma solidity >=0.5.0 <0.7.0;

import "./IERC1155Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
  contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}
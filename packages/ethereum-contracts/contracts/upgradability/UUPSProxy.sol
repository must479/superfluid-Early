// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.12;

import { UUPSUtils } from "./UUPSUtils.sol";
import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxy
 *
 * NOTE:
 * - Compliant with [Universal Upgradeable Proxy Standard](https://eips.ethereum.org/EIPS/eip-1822)
 * - Compiiant with [Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
 * - Implements delegation of calls to other contracts, with proper forwarding of
 *   return values and bubbling of failures.
 * - It defines a fallback function that delegates all calls to the implementation.
 */
contract UUPSProxy is Proxy {

    /// UUPSProxy: zero address
    error LogicZeroAddress();

    /// UUPSProxy: already initialized
    error AlreadyInitialized();

    /**
     * @dev Proxy initialization function.
     *      This should only be called once and it is permission-less.
     * @param initialAddress Initial logic contract code address to be used.
     */
    function initializeProxy(address initialAddress) external {
        if (initialAddress == address(0)) revert LogicZeroAddress();
        if (UUPSUtils.implementation() != address(0)) revert AlreadyInitialized();
        UUPSUtils.setImplementation(initialAddress);
    }

    /// @dev Proxy._implementation implementation
    function _implementation() internal virtual override view returns (address)
    {
        return UUPSUtils.implementation();
    }

}

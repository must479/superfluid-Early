// SPDX-License-Identifier: AGPLv3
pragma solidity 0.7.6;

import {
    ISuperToken,
    CustomSuperTokenProxyBase
}
from "../interfaces/superfluid/CustomSuperTokenProxyBase.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UUPSProxy } from "../upgradability/UUPSProxy.sol";


/**
 * @dev Wrapped ETH interface
 */
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


/**
 * @dev Super ETH (SETH) custom token functions
 *
 * @author Superfluid
 */
interface ISETHCustom {
    // using native token
    function upgradeByETH() external payable;
    function upgradeByETHTo(address to) external payable;
    function downgradeToETH(uint wad) external;

    // using wrapped native token
    function getUnderlyingToken() external view returns(address tokenAddr);
    function upgrade(uint256 amount) external;
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;
    function downgrade(uint256 amount) external;
}

/**
 * @dev Super ETH (SETH) full interface
 *
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface ISETH is ISETHCustom, ISuperToken {
    function getUnderlyingToken() external override(ISETHCustom, ISuperToken) view returns(address tokenAddr);
    function upgrade(uint256 amount) external override(ISETHCustom, ISuperToken);
    function upgradeTo(address to, uint256 amount, bytes calldata data) external override(ISETHCustom, ISuperToken);
    function downgrade(uint256 amount) external override(ISETHCustom, ISuperToken);
}

/**
 * SETH receive fallback logic contract
 */
contract SETHReceiveLogic {

    IWETH immutable private _weth;

    constructor(IWETH weth) {
        _weth = weth;
    }

    receive() external payable {
        if (msg.sender != address(_weth)) {
            // if non weth contract sends us eth, we upgrade some SETH to them
            ISuperToken(address(this)).selfMint(msg.sender, msg.value, new bytes(0));
        } // else it is weth, it is already implemented in upgrade (ByWETH)
    }
}

/**
 * @dev Super ETH (SETH) custom super totken implementation
 *
 * @author Superfluid
 */
contract SETHProxy is ISETHCustom, CustomSuperTokenProxyBase {

    IWETH immutable private _weth;
    SETHReceiveLogic private _receiveLogic;

    constructor(IWETH weth) {
        _weth = weth;
        _receiveLogic = new SETHReceiveLogic(weth);
    }

    function _implementation() internal override view returns (address)
    {
        if (msg.data.length > 0) {
            return UUPSProxy._implementation();
        } else {
            // do not provide receive() fallback otherwise it can't
            // withdraw WETH
            return address(_receiveLogic);
        }
    }

    function upgradeByETH() external override payable {
        ISuperToken(address(this)).selfMint(msg.sender, msg.value, new bytes(0));
        emit TokenUpgraded(msg.sender, msg.value);
    }

    function upgradeByETHTo(address to) external override payable {
        ISuperToken(address(this)).selfMint(to, msg.value, new bytes(0));
        emit TokenUpgraded(to, msg.value);
    }

    function downgradeToETH(uint wad) external override {
        ISuperToken(address(this)).selfBurn(msg.sender, wad, new bytes(0));
        msg.sender.transfer(wad);
        emit TokenDowngraded(msg.sender, wad);
    }

    function getUnderlyingToken()
        external override view
        returns(address tokenAddr)
    {
        return address(_weth);
    }

    function upgrade(uint wad) external override {
        _weth.transferFrom(msg.sender, address(this), wad);
        // this will trigger receive() which is overriden to a no-op
        _weth.withdraw(wad);
        ISuperToken(address(this)).selfMint(msg.sender, wad, new bytes(0));
        emit TokenUpgraded(msg.sender, wad);
    }

    function upgradeTo(address to, uint256 wad, bytes calldata data) external override {
        _weth.transferFrom(msg.sender, address(this), wad);
        // this will trigger receive() which is overriden to a no-op
        _weth.withdraw(wad);
        ISuperToken(address(this)).selfMint(to, wad, data);
        emit TokenUpgraded(msg.sender, wad);
    }

    function downgrade(uint256 wad) external override {
        ISuperToken(address(this)).selfBurn(msg.sender, wad, new bytes(0));
        _weth.deposit{ value: wad }();
        _weth.transfer(msg.sender, wad);
        emit TokenDowngraded(msg.sender, wad);
    }

    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

}

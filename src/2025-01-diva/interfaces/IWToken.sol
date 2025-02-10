// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Interface for the wrapped token (wToken) contract that serves as proxy collateral in DIVA Protocol.
 * @dev The `WToken` contract inherits from ERC20 contract and represents a wrapped version of the 
 * collateral token (e.g., wUSDC for USDC). It is deployed when a collateral token is registered via 
 * AaveDIVAWrapper's `registerCollateralToken` function. It implements `mint` and `burn` functions which 
 * can only be called by the AaveDIVAWrapper contract (the owner).
 */
interface IWToken is IERC20 {
    /**
     * @notice Function to mint ERC20 wTokens.
     * @dev Called during `createContingentPool` and `addLiquidity`.
     * Can only be called by the owner of the wToken which is AaveDIVAWrapper.
     * @param _recipient The account receiving the wTokens.
     * @param _amount The number of wTokens to mint.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @notice Function to burn wTokens.
     * @dev Called within `redeemWToken`, `redeemPositionToken`, and `removeLiquidity`.
     * Can only be called by the owner of the wToken which is AaveDIVAWrapper.
     * @param _redeemer Address redeeming wTokens.
     * @param _amount The number of wTokens to burn.
     */
    function burn(address _redeemer, uint256 _amount) external;

    /**
     * @notice Returns the owner of the wToken (AaveDIVAWrapper).
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of decimals of the wToken.
     */
    function decimals() external view returns (uint8);
}

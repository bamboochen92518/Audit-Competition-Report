// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ValidatorRewarderStorage {
    /// @notice The QI token
    IERC20 public qi;

    /// @notice The Ignite contract address
    address public ignite;

    /// @notice Target APR (bps)
    uint public targetApr;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IERC4626} from '@openzeppelin/contracts/interfaces/IERC4626.sol';

/**
 * @title ITermMaxVault
 * @notice Interface for TermMax vaults that implement ERC4626Updatable with enhanced features
 */
interface ITermMaxVault is IERC4626 {
    // Additional events
    event OrderCreated(address indexed user, uint256 amount, uint256 orderId);
    event BadDebtDealt(uint256 amount);
    event PendingMinApySubmitted(uint256 newMinApy);

    // Enhanced ERC4626 methods with additional checks are inherited from IERC4626

    // Governance and state functions that actually exist
    function paused() external view returns (bool);
    function curator() external view returns (address);
    function guardian() external view returns (address);
    function owner() external view returns (address);

    // Financial parameters that actually exist
    function apy() external view returns (uint256);
    function minApy() external view returns (uint256);
    function performanceFee() external view returns (uint256);
}
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

    // Enhanced ERC4626 methods with additional checks
    function maxDeposit(address owner) external view override returns (uint256);
    function totalAssets() external view override returns (uint256);

    // TermMax-specific methods
    function createOrder(uint256 amount) external returns (uint256 orderId);
    function withdrawFts(uint256 amount) external;
    function dealBadDebt(uint256 amount) external;
    function submitPendingMinApy(uint256 newMinApy) external;

    // Governance and state
    function paused() external view returns (bool);
    function curator() external view returns (address);
    function guardian() external view returns (address);
    function owner() external view returns (address);

    // Capacity and limits
    function depositCap() external view returns (uint256);
    function minApy() external view returns (uint256);
    function performanceFee() external view returns (uint256);

    // Pool and market management
    function isPoolWhitelisted(address pool) external view returns (bool);
    function isMarketWhitelisted(address market) external view returns (bool);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesting {
    function MAX_LOCK_LENGTH() external view returns (uint256);

    function claimed() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function token() external view returns (IERC20);

    function startAt() external view returns (uint256);

    function shares(uint256 index) external view returns (uint256);

    function unlocks(uint256 index) external view returns (uint256);

    // @dev Claim if possible.
    // throw if no reward
    function claim() external;

    // @dev Returns next claim details.
    function nextClaim()
        external
        view
        returns (uint256 reward, uint256 unlockedShares, uint256 timestamp);
}

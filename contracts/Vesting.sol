// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVesting.sol";

// @title Vesting - simple contract with hardset unlocks and shares.
contract Vesting is Ownable, IVesting {
    uint256 public constant override MAX_LOCK_LENGTH = 100;

    uint256 public override claimed;
    uint256 public immutable override totalShares;

    IERC20 public immutable override token;
    uint256 public immutable override startAt;
    uint256[] private _shares;
    uint256[] private _unlocks;

    constructor(
        IERC20 _token,
        uint256 _startAt,
        uint256[] memory shares_,
        uint256[] memory _unlocksAt
    ) {
        require(_startAt > block.timestamp, "Vesting: unlock time in the past");

        token = _token;
        startAt = _startAt;

        require(
            shares_.length == _unlocksAt.length,
            "Unlocks and shares_ length not equal"
        );
        require(shares_.length != 0, "Empty vesting program");
        require(shares_.length <= MAX_LOCK_LENGTH, "Max lock length overflow");

        uint256 _totalShares;
        for (uint256 i; i < shares_.length; i++) {
            require(shares_[i] != 0, "Zero share set");

            if (i == 0) {
                require(
                    _unlocksAt[i] >= _startAt,
                    "Previous timestamp higher then current"
                );
            } else {
                require(
                    _unlocksAt[i] > _unlocksAt[i - 1],
                    "Previous timestamp higher then current"
                );
            }

            _totalShares += shares_[i];
        }

        _shares = shares_;
        _unlocks = _unlocksAt;
        totalShares = _totalShares;
    }

    function claim() external override onlyAfter(startAt) {
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 len = _unlocks.length;
        uint256 unlockedShares;
        for (uint256 i; i < len; i++) {
            if (_unlocks[i] <= block.timestamp) {
                if (i < _shares.length) {
                    unlockedShares += _shares[i];
                }
            } else {
                i = len; // end loop
            }
        }

        uint256 reward = (unlockedShares * amount) / totalShares;
        if (reward != 0) {
            reward -= claimed;
        }

        require(reward != 0, "No reward");

        claimed += reward;
        IERC20(token).transfer(owner(), reward);
    }

    function nextClaim()
        external
        view
        override
        returns (uint256 reward, uint256 unlockedShares, uint256 timestamp)
    {
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 len = _unlocks.length;
        for (uint256 i; i < len; i++) {
            if (_unlocks[i] <= block.timestamp) {
                unlockedShares += _shares[i];
                timestamp = block.timestamp;
            } else {
                timestamp = _unlocks[i];
                i = len; // end loop
            }
        }
        if (unlockedShares == 0) {
            unlockedShares += _shares[0];
            timestamp = _unlocks[0];
        }
        if (unlockedShares == totalShares) {
            timestamp = 0;
        }

        reward = (unlockedShares * amount) / totalShares;
        if (reward != 0) {
            reward -= claimed;
        }
    }

    // @dev Returns how much _unlocks available.
    function countUnlocks() external view returns (uint256 result) {
        result = _unlocks.length;
    }

    function shares(uint256 _index) external view override returns (uint256) {
        require(_index < _shares.length, "Key not exist");

        return _shares[_index];
    }

    function unlocks(uint256 _index) external view override returns (uint256) {
        require(_index < _unlocks.length, "Key not exist");

        return _unlocks[_index];
    }

    modifier onlyAfter(uint256 _timestamp) {
        require(_timestamp < block.timestamp, "Its not a time");
        _;
    }
}

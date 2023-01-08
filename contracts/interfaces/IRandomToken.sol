// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRandomToken {
    // struct User {
    //     address owner;
    //     string username;
    //     uint256 id;
    // }

    event ChampionUpgraded(
        uint256 _tokenId,
        bool _attackPowerIncreased,
        bool _defensePowerIncreased
    );

    error ValueSentIsTooLow(uint256 _value);
    error NoStatsToIncrease();
    error TokenDoesNotExist();
    error Unauthorized();
    error Underpriced();
    error MaxSupplyReached();

    struct Champion {
        uint128 attackPower;
        uint128 defensePower;
    }

    enum Status {
        VICTORY,
        DEFEAT
    }
}

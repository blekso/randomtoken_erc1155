// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IRandomToken.sol";

import "hardhat/console.sol";

contract RandomToken is ERC1155, Ownable, IRandomToken, AccessControl {
    uint256 public price;
    uint256 public rewardAmount;
    uint256 public upgradePrice;

    uint64 public battleCount;
    uint32 public currentSupply;
    uint32 public maxSupply;

    mapping(uint256 => address) public battleWinner;
    mapping(uint256 => Champion) public tokenIdToChampion;
    mapping(address => uint256[]) public userOwnedChampions;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint32 _maxSupply,
        uint256 _rewardAmount
    ) ERC1155(_uri) {
        price = _price;
        maxSupply = _maxSupply;
        rewardAmount = _rewardAmount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint() external payable {
        if (msg.value < price) revert Underpriced();
        if (currentSupply + 1 > maxSupply) revert MaxSupplyReached();

        Champion memory newChampion = _createRandomChampion(++currentSupply);
        tokenIdToChampion[currentSupply] = newChampion;

        _mint(msg.sender, currentSupply, 1, "");

        userOwnedChampions[payable(msg.sender)].push(newChampion);
    }

    function rewardPlayer(address player) internal {
        _mint(player, rewardAmount, 1, "");
    }

    function attack(uint256 _myChampion, uint256 _enemyChampion) external {
        if (
            userOwnedChampions[_myChampion] != msg.sender &&
            userOwnedChampions[_enemyChampion] == msg.sender
        ) revert Unauthorized();

        if (
            tokenIdToChampion[_enemyChampion].defensePower <
            tokenIdToChampion[_myChampion].attackPower
        ) {
            address attacker = msg.sender;
            battleWinner[++battleCount] = attacker;

            rewardPlayer(attacker);
        } else {
            address defender = owner(_enemyChampion);
            battleWinner[++battleCount] = defender;

            rewardPlayer(defender);
        }
    }

    function upgradeChampion(
        uint256 _myChampion,
        bool attackPowerIncrease,
        bool defensePowerIncrease
    ) external payable {
        if (userOwnedChampions[_myChampion] == address(0))
            revert TokenDoesNotExist();
        if (!attackPowerIncrease && !defensePowerIncrease)
            revert NoStatsToIncrease();

        if (attackPowerIncrease && defensePowerIncrease) {
            if (msg.value < 2 * upgradePrice)
                revert ValueSentIsTooLow(msg.value);
        } else {
            if (msg.value < upgradePrice) revert ValueSentIsTooLow(msg.value);
        }

        if (attackPowerIncrease) {
            tokenIdToChampion[_myChampion].attackPower += 10;
        }
        if (defensePowerIncrease) {
            tokenIdToChampion[_myChampion].defensePower += 10;
        }

        emit ChampionUpgraded(
            _myChampion,
            attackPowerIncrease,
            defensePowerIncrease
        );
    }

    function setUpgradePrice(uint256 _upgradePrice) external onlyOwner {
        upgradePrice = _upgradePrice;
    }

    function _createRandomChampion(uint256 _tokenId)
        private
        view
        returns (Champion memory champion)
    {
        uint128 randomAtk = uint128(
            uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp))) %
                maxSupply
        );

        uint128 randomDef = uint128(
            uint256(keccak256(abi.encodePacked(_tokenId, block.number))) %
                maxSupply
        );

        return Champion({attackPower: randomAtk, defensePower: randomDef});

        tokenIdToChampion[++currentSupply] = this.onERC1155Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

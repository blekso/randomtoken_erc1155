// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/IRandomToken.sol";

import "hardhat/console.sol";

contract RandomToken is
    ERC1155,
    Ownable,
    IRandomToken,
    AccessControl,
    ERC1155Holder
{
    uint256 public price;
    uint256 public rewardAmount;
    uint256 public upgradePrice;

    uint64 public battleCount;
    uint32 public currentSupply;
    uint32 public maxSupply;

    mapping(uint256 => address) public battleWinner;
    mapping(uint256 => Champion) public tokenIdToChampion;

    constructor(
        string memory _uri,
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
        override(ERC1155, AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 id) external payable {
        if (msg.value < price) revert Underpriced();
        if (currentSupply + 1 > maxSupply) revert MaxSupplyReached();

        Champion memory newChampion = _createRandomChampion(++currentSupply);
        tokenIdToChampion[currentSupply] = newChampion;

        _mint(msg.sender, currentSupply, id, "");
    }

    function rewardPlayer(address player) internal {
        _mint(player, rewardAmount, 1, "");
    }

    function attack(uint256 _myChampionId, uint256 _enemyChampionId) external {
        if (
            balanceOf(msg.sender, _myChampionId) != 0 &&
            balanceOf(msg.sender, _enemyChampionId) == 1
        ) revert Unauthorized();

        if (
            tokenIdToChampion[_enemyChampionId].defensePower <
            tokenIdToChampion[_myChampionId].attackPower
        ) {
            address attacker = msg.sender;
            battleWinner[++battleCount] = attacker;

            rewardPlayer(attacker);
        } /* else {
            address defender = owner(_enemyChampionId);
            battleWinner[++battleCount] = defender;

            rewardPlayer(defender);
        } */
    }

    function upgradeChampion(
        uint256 _myChampionId,
        bool attackPowerIncrease,
        bool defensePowerIncrease
    ) external payable {
        if (balanceOf(address(0), _myChampionId) == 1)
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
            tokenIdToChampion[_myChampionId].attackPower += 10;
        }
        if (defensePowerIncrease) {
            tokenIdToChampion[_myChampionId].defensePower += 10;
        }

        emit ChampionUpgraded(
            _myChampionId,
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
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function swapChampion(uint256 _myChampionId, uint256 _wantedChampionId)
        external
        payable
    {
        if (balanceOf(msg.sender, _myChampionId) == 1) revert Underpriced();

        require(
            balanceOf(address(this), _wantedChampionId) == 1,
            "Sorry, wanted champion id is currently not in stock."
        );

        this.safeTransferFrom(msg.sender, address(this), _myChampionId, 1, "");
        this.safeTransferFrom(
            address(this),
            msg.sender,
            _wantedChampionId,
            1,
            ""
        );
    }
}

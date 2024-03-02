// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IGabby.sol";
import "./interface/IGabbyLand.sol";
import "./interface/IGabbyPrompt.sol";
import "./utils/SigUtilsUpgradeable.sol";
import "./interface/IGabbyMasterpiece.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract GabbyCreationTemple is Initializable, OwnableUpgradeable, SigUtilsUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _landTaskIds;

    IGabby public gabby;
    IGabbyLand public land;
    IGabbyPrompt1155 public prompt;
    IGabbyMasterpiece public masterpiece;
    bool[100] public selectedMapIndex;
    uint256[100] public map;
    address public guard;

    struct LandMint {
        uint256 landId;
        uint256 taskId;
        uint256 index;
    }

    mapping(uint256 => LandMint) public landMint;
    mapping(address => bool) public gabbyMint;

    function occupiedMap() public view returns (uint256[] memory indexes, uint256[] memory tokenIds) {
        uint256 count = 0;
        for (uint256 i = 1; i < 100; i++) {
            if (map[i] != 0) {
                count++;
            }
        }

        indexes = new uint256[](count);
        tokenIds = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = 1; i < 100; i++) {
            if (map[i] != 0) {
                indexes[index] = i;
                tokenIds[index] = map[i];
                index++;
            }
        }
    }

    function occupiedMapIndex() public view returns (uint256[] memory) {
        uint256[] memory index = new uint256[](99);
        uint256 count = 0;

        for (uint256 i = 1; i < 100; i++) {
            if (!selectedMapIndex[i]) {
                index[count] = i;
                count++;
            }
        }

        assembly {
            mstore(index, count)
        }

        return index;
    }

    function initialize(address masterpiece_, address prompt1155_, address land_, address guard_) public initializer {
        __Ownable_init();
        setBanker(_msgSender());

        masterpiece = IGabbyMasterpiece(masterpiece_);
        prompt = IGabbyPrompt1155(prompt1155_);
        land = IGabbyLand(land_);

        guard = guard_;
    }

    function createGabby(bool sex_, uint256 age_, string memory name_) external returns (uint256) {
        address sender = _msgSender();
        require(!gabbyMint[sender], "minted");
        gabbyMint[sender] = true;

        uint256 tokenId = gabby.mint(sender, sex_, age_, name_);

        return tokenId;
    }

    event NewLandTask(address account, uint256 masterPieceId_, uint256 taskId, string style, string[] description);

    function newLandTask(uint256 masterpieceId_, string memory style_, string[] memory description_) external returns (uint256) {
        require(masterpiece.ownerOf(masterpieceId_) == _msgSender(), "not owner of masterpiece");

        LandMint storage task = landMint[masterpieceId_];

        require(task.landId == 0, "already minted");
        require(task.index > 0, "no index selected");

        require(bytes(style_).length < 26, "too many character style");

        uint count = description_.length;
        for (uint i = 0; i < count; i++) {
            require(bytes(description_[i]).length < 26, "too many character description");
        }

        address sender = _msgSender();

        require(prompt.balanceOf(sender, 0) >= count, "prompt enough");
        prompt.burn(sender, count);

        _landTaskIds.increment();
        uint256 taskId = _landTaskIds.current();

        task.taskId = taskId;

        emit NewLandTask(sender, masterpieceId_, taskId, style_, description_);
        return taskId;
    }

    function selectLandIndex(uint256 masterpieceId_, uint256 index_) external {
        require(masterpiece.ownerOf(masterpieceId_) == _msgSender(), "not owner of masterpiece");

        LandMint storage info = landMint[masterpieceId_];
        require(info.landId == 0, "already minted");
        require(info.index == 0, "already selected");
        require(index_ > 0 && index_ < 100, "wrong position");

        require(!selectedMapIndex[index_], "occupied position");

        info.index = index_;
        selectedMapIndex[index_] = true;
    }

    event CreateLand(uint256 masterPieceId, uint256 tokenId, uint256 taskId);

    function createLand(uint256 timestamp_, uint256 masterpieceId_, uint256 taskId_, string memory style_, string memory description_, bytes calldata signature_) external returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(timestamp_, masterpieceId_, taskId_, _msgSender(), style_, description_));
        require(verifySignature(hash, signature_), "signature error");
        require(block.timestamp < timestamp_, "exceed time");

        require(masterpiece.ownerOf(masterpieceId_) == _msgSender(), "not owner of masterpiece");

        LandMint storage task = landMint[masterpieceId_];

        require(task.landId == 0, "already minted");
        require(task.taskId == taskId_, "already updated task");
        require(task.index > 0, "no index selected");

        uint256 index = task.index;
        uint tokenId = land.mint(_msgSender(), 1, index, masterpieceId_, guard, style_, description_);

        task.landId = tokenId;
        map[index] = tokenId;

        emit CreateLand(masterpieceId_, tokenId, taskId_);

        return tokenId;
    }
}

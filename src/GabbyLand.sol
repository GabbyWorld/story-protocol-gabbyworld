// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "contracts/utils/Minter.sol";
import "contracts/utils/TBA.sol";
import "contracts/utils/Gabby721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@story-protocol/protocol-core/contracts/lib/IP.sol";
import "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import "@story-protocol/protocol-core/contracts/resolvers/IPResolver.sol";

contract GabbyLand is Gabby721, Minter {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _counts;

    IERC721 public masterpiece;
    IPAssetRegistry public ipaRegistry;
    IPResolver public ipResolver;

    struct Land {
        uint256 location;
        uint256 index;
        uint256 createMinPrompt;
        uint256 prosperity;
        uint256 landlord;
        uint256 builders;
        uint256 explorers;
        string style;
        string description;
    }

    struct Guard {
        address guard;
        uint256 masterpieceId;
    }

    mapping(uint256 => Land) public landInfoes;
    mapping(uint256 => Guard) public landGuard;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address ipaRegistryAddress,
        address ipResolverAddress
    ) Gabby721(name_, symbol_, baseURI_) {
        setSuperMinter(_msgSender());
        ipaRegistry = IPAssetRegistry(ipaRegistryAddress);
        ipResolver = IPResolver(ipResolverAddress);
    }

    event Mint(address account, uint256 tokenId, uint256 position, string name, string description);

    function parseInt(string memory value_) public pure returns (uint256) {
        bytes memory b = bytes(value_);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function mint(address to_, uint256 location_, uint256 index_, uint256 masterpieceId_, address guard_, string memory style_, string memory description_, string memory ipData) public onlyMinter(1) returns (uint256) {
        _counts.increment();
        uint256 count = _counts.current();

        uint256 tokenId = parseInt(string(abi.encodePacked(location_.toString(), "0", count.toString())));
        _spendQuota(1);

        Land storage landInfo = landInfoes[tokenId];

        landInfo.location = location_;
        landInfo.index = index_;
        landInfo.style = style_;
        landInfo.description = description_;

        if (guard_ != address(0)) {
            landGuard[tokenId] = Guard({ guard: guard_, masterpieceId: masterpieceId_ });
        }

        _mint(to_, tokenId);

        // IP registration logic using IPARegistrar functionality
        ipaRegistry.registerIP(address(this), tokenId, ipData); // Assuming registerIP function exists and matches this signature

        return tokenId;
    }

    function setReward(uint256 tokenId_, uint256 minPrompt_, uint256 landlord_, uint256 builders_, uint256 explorers_) public {
        Guard memory guardInfo = landGuard[tokenId_];

        address banker = guardInfo.guard == address(0) ? ownerOf(tokenId_) : masterpiece.ownerOf(guardInfo.masterpieceId);
        require(banker == _msgSender(), "not owner or masterpiece owner");

        require(landlord_ + builders_ + explorers_ == 100, "wrong proportion");
        Land storage landInfo = landInfoes[tokenId_];

        landInfo.createMinPrompt = minPrompt_;
        landInfo.landlord = landlord_;
        landInfo.builders = builders_;
        landInfo.explorers = explorers_;
    }

    function _afterTokenTransfer(address from_, address to_, uint256 firstTokenId_, uint256) internal virtual override {
        if (to_ == address(0)) {
            delete landInfoes[firstTokenId_];
            delete landGuard[firstTokenId_];
            return;
        }

        if (from_ != address(0)) {
            address guard = landGuard[firstTokenId_].guard;
            if (guard != address(0)) {
                require(_msgSender() == guard, "sender is not guard of the token");
            }
        }
    }
}

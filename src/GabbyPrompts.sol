// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "contracts/utils/Gabby721.sol";

contract GabbyPrompts is Gabby721 {
    struct TokenInfo {
        uint256 time;
        string context;
    }
    mapping(uint256 => TokenInfo) public tokenInfoes;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) Gabby721(name_, symbol_, baseURI_) {}

    function batchTokenId(address account_) public view returns (uint256[] memory) {
        uint256 amount = balanceOf(account_);
        uint256[] memory idInfo = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            idInfo[i] = tokenOfOwnerByIndex(account_, i);
        }
        return idInfo;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (ownerOf(_tokenId) == address(0)) {
            return "";
        }
        return "";
    }

    event Mint(address account, uint256 pid);
}

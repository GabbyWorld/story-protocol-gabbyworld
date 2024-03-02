// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    uint8 private _decimal;
    mapping(address => bool) public admin;

    constructor(string memory name_, string memory symbol_, uint8 decimal_) ERC20(name_, symbol_) {
        admin[_msgSender()] = true;
        _decimal = decimal_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function mint(address addr_, uint256 amount_) public onlyAdmin {
        _mint(addr_, amount_);
    }

    modifier onlyAdmin() {
        require(admin[_msgSender()], "not damin");
        _;
    }

    function setAdmin(address com_) public onlyOwner {
        require(com_ != address(0), "wrong adress");
        admin[com_] = true;
    }
}

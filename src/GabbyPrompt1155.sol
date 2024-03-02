// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ERC1155Enumerable.sol";
import "./utils/Minter.sol";

contract GabbyPrompt1155 is ERC1155, Ownable, Minter {
    using Address for address;

    string private _name;
    string private _symbol;
    uint private _totalSupply;

    constructor(string memory __name, string memory __symbol, string memory _uri) ERC1155(_uri) {
        _name = __name;
        _symbol = __symbol;
        setSuperMinter(_msgSender());
    }

    event Burn(address account, uint256 amount);

    function mint(address to_, uint amount_) public returns (bool) {
        _spendQuota(amount_);

        _totalSupply += amount_;

        _mint(to_, 0, amount_, "");
        return true;
    }

    function mintBatch(address[] calldata _accounts, uint256[] calldata _amounts) public {
        require(_accounts.length == _amounts.length, "GP: accounts and amounts length mismatch");

        uint256 total;
        for (uint i = 0; i < _amounts.length; ++i) {
            total += _amounts[i];
            _mint(_accounts[i], 0, _amounts[i], "");
        }

        _spendQuota(total);
    }

    function burn(address _account, uint256 _amount) public {
        require(_account == _msgSender() || isApprovedForAll(_account, _msgSender()), "GP: caller is not owner nor approved");

        _totalSupply -= _amount;

        _burn(_account, 0, _amount);

        emit Burn(_account, _amount);
    }

    /******************************* view function *******************************/

    function uri(uint256 _tokenId) public view override returns (string memory) {
        // require(exists(_id), "URI: nonexistent token");
        return _tokenId == 0 ? super.uri(0) : "";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /******************************* internal function *******************************/

    /******************************* auth function *******************************/

    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }
}

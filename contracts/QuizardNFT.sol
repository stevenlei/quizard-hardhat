// SPDX-License-Identifier: UNLICENSED

// This is the ERC721 NFT Contract for students who pass the Quizard

pragma solidity ^0.8.4;

import "./QuizardManager.sol";
import "./Quizard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuizardNFT is
    IERC721,
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _name;
    string private _symbol;
    bool private _transferable = false;
    address private _quizardManager;

    constructor(
        string memory name_,
        string memory symbol_,
        bool transferable_,
        address quizardManager
    ) ERC721("", "") {
        _name = name_;
        _symbol = symbol_;
        _transferable = transferable_;
        _quizardManager = quizardManager;
    }

    function updateSettings(
        string memory name_,
        string memory symbol_,
        bool transferable_
    ) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
        _transferable = transferable_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function setName(string memory name_) public onlyOwner {
        _name = name_;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setSymbol(string memory symbol_) public onlyOwner {
        _symbol = symbol_;
    }

    function transferable() public view returns (bool) {
        return _transferable;
    }

    function setTransferable(bool transferable_) public onlyOwner {
        _transferable = transferable_;
    }

    function mintQuizardNFTForStudent(address quizard, address student)
        public
        payable
        onlyNFTDistributor
        returns (uint256)
    {
        Quizard quizardContract = Quizard(quizard);
        require(
            quizardContract.isEligibleToClaimNFT(student) == true,
            "Student is not eligible to claim the NFT"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(student, newItemId);

        // Set the JSON string on chain
        _setTokenURI(newItemId, "");

        // Record the minted status
        quizardContract.setClaimed(student);

        return newItemId;
    }

    modifier onlyNFTDistributor() {
        require(
            QuizardManager(_quizardManager).getNFTDistributor() == msg.sender,
            "only NFT Distributor can mint NFT"
        );
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "no tokens to withdraw");

        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(_transferable, "not transferable token");

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(_transferable, "not transferable token");

        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        require(_transferable, "not transferable token");

        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

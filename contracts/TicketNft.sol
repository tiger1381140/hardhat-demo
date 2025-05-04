// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketNft is ERC721, Ownable {
    uint256 public nextTokenId;
    string public baseTokenURI;

    // 记录哪些票已经被验证（用于入场）
    mapping(uint256 => bool) public isValidated;

    constructor(string memory _baseTokenURI)
        ERC721("TicketNft", "TICKET")
        Ownable(msg.sender)
    {
        baseTokenURI = _baseTokenURI;
    }

    // 主办方发票（mint）
    function issueTicket(address to) external onlyOwner {
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }

    // 入场验证
    function validateTicket(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this ticket");
        require(!isValidated[tokenId], "Ticket already validated");
        isValidated[tokenId] = true;
    }

    // 设置 baseURI（可选）
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./WTFApe.sol";

contract NFTSwap is IERC721Receiver {
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);

    /* 定义order结构体 */
    struct Order {
        address owner;
        uint256 price;
    }

    /* NFT Order映射 */
    mapping(address => mapping(uint256 => Order)) public nftList;

    receive() external payable {}
    fallback() external payable {}

    /* 挂单: 卖家上架NFT，合约地址为_nftAddr，tokenId为_tokenId，价格_price为以太坊（单位是wei） */
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        /* 声明IERC721接口合约变量 */
        IERC721 _nft = IERC721(_nftAddr);

        /* 合约得到授权 ,价格大于0*/
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval");
        require(_price > 0);

        /* 设置NFT持有人和价格 */
        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;

        /* 将NFT转账到合约 */
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        /* 释放List事件 */
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    /* 购买: 买家购买NFT，合约为_nftAddr，tokenId为_tokenId，调用函数时要附带ETH */
    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        /* 取得Order */
        Order storage _order = nftList[_nftAddr][_tokenId];

        /* NFT价格大于0 , 购买价格大于标价*/
        require(_order.price > 0, "Invalid Price");
        require(msg.value >= _order.price, "Increase price");

        /* 声明IERC721接口合约变量 */
        IERC721 _nft = IERC721(_nftAddr);

        /* NFT在合约中 */
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        /* 将NFT转给买家 */
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        /* 将ETH转给卖家 */
        payable(_order.owner).transfer(_order.price);

        /* 多余ETH给买家退款 */
        if (msg.value > _order.price) {
            payable(msg.sender).transfer(msg.value - _order.price);
        }

        /* 释放Purchase事件 */
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);

        /* 删除order */
        delete nftList[_nftAddr][_tokenId];
    }

    /* 撤单： 卖家取消挂单 */
    function revoke(address _nftAddr, uint256 _tokenId) public {
        /* 取得Order */
        Order storage _order = nftList[_nftAddr][_tokenId];

        /* 必须由持有人发起 */
        require(_order.owner == msg.sender, "Not Owner");

        /* 声明IERC721接口合约变量 */
        IERC721 _nft = IERC721(_nftAddr);

        /* NFT在合约中 */
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        /* 将NFT转给卖家 */
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        /* 删除order */
        delete nftList[_nftAddr][_tokenId];

        /* 释放Revoke事件 */
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    /* 调整价格: 卖家调整挂单价格 */
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        /* NFT价格大于0 */
        require(_newPrice > 0, "Invalid Price");

        /* 取得Order , 必须由持有人发起*/
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(_order.owner == msg.sender, "Not Owner");

        /* 声明IERC721接口合约变量 , NFT在合约中*/
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        /* 调整NFT价格 */
        _order.price = _newPrice;

        /* 释放Update事件 */
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    // 实现{IERC721Receiver}的onERC721Received，能够接收ERC721代币
    function onERC721Received(
        address ,
        address ,
        uint256 ,
        bytes calldata 
    ) external pure override returns (bytes4) {
        //return IERC721Receiver.onERC721Received.selector;
        return this.onERC721Received.selector;
    }
}
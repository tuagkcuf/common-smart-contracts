// Dutch auction for NFT

// Auction

// 1. Seller of NFT deploys this contract setting a starting price for the NFT
// 2. Auction lasts for 7 days
// 3. Price of NFT decreases over time
// 4. Participants can buy by depositing ETH greater than the current price computed by the smart contract
// 5. Auction ends when a buyer buys the NFT

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;
    address public immutable owner;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startsAt;
    uint public immutable expiresAt;
    uint public immutable discountRate;

    modifier isOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(uint _startingPrice, uint _discountRate, address _nft, uint _nftId) {
        owner = msg.sender;
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startsAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        require(_startingPrice >= _discountRate * DURATION, "starting price < min");

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startsAt;
        uint discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "auction expired");

        uint price = getPrice();
        require(msg.value >= price, "ETH < price");

        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function withdraw() external payable isOwner {
        payable(owner).call{value: address(this).balance};
    }
}
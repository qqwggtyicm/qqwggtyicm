// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public buyerApproved;
    bool public sellerApproved;

    constructor(address _seller, address _arbiter) {
        seller = _seller;
        arbiter = _arbiter;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only buyer can deposit");
    }

    function approve() public {
        if (msg.sender == buyer) {
            buyerApproved = true;
        } else if (msg.sender == seller) {
            sellerApproved = true;
        }
    }

    function release() public {
        require(buyerApproved && sellerApproved, "Both parties must approve");
        payable(seller).transfer(address(this).balance);
    }

    function refund() public {
        require(!buyerApproved || !sellerApproved, "Both parties cannot approve");
        payable(buyer).transfer(address(this).balance);
    }
}

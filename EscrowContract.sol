// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public buyerApproved;
    bool public sellerApproved;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event ApprovalReceived(address indexed approver);
    event FundsReleased(uint256 amount);
    event FundsRefunded(uint256 amount);

    constructor(address _seller, address _arbiter) {
        seller = _seller;
        arbiter = _arbiter;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function approve() public {
        require(msg.sender == buyer || msg.sender == seller, "Unauthorized");
        if (msg.sender == buyer) {
            require(!buyerApproved, "Already approved by buyer");
            buyerApproved = true;
        } else {
            require(!sellerApproved, "Already approved by seller");
            sellerApproved = true;
        }
        emit ApprovalReceived(msg.sender);
    }

    function release() public {
        require(buyerApproved && sellerApproved, "Both parties must approve");
        uint256 amount = address(this).balance;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Failed to release funds");
        emit FundsReleased(amount);
    }

    function refund() public {
        require(!buyerApproved || !sellerApproved, "Both parties cannot approve");
        uint256 amount = address(this).balance;
        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Failed to refund funds");
        emit FundsRefunded(amount);
    }
}

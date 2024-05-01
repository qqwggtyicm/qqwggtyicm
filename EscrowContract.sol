// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public buyerApproved;
    bool public sellerApproved;
    bool public fundsReleased;
    bool public fundsRefunded;
    uint256 public escrowEndTime;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event ApprovalReceived(address indexed approver);
    event FundsReleased(uint256 amount, address indexed recipient);
    event FundsRefunded(uint256 amount, address indexed recipient);
    event EscrowExpired();

    modifier onlyParty() {
        require(msg.sender == buyer || msg.sender == seller || msg.sender == arbiter, "Unauthorized");
        _;
    }

    modifier escrowActive() {
        require(!fundsReleased && !fundsRefunded && !buyerApproved && !sellerApproved, "Escrow already settled");
        require(block.timestamp < escrowEndTime || escrowEndTime == 0, "Escrow expired");
        _;
    }

    constructor(address _seller, address _arbiter, uint256 _escrowDuration) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        escrowEndTime = block.timestamp + _escrowDuration;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function approve() public onlyParty escrowActive {
        if (msg.sender == buyer) {
            require(!buyerApproved, "Already approved by buyer");
            buyerApproved = true;
        } else {
            require(!sellerApproved, "Already approved by seller");
            sellerApproved = true;
        }
        emit ApprovalReceived(msg.sender);
    }

    function release() public onlyParty {
        require((msg.sender == arbiter && (buyerApproved || sellerApproved)) || (msg.sender == buyer && sellerApproved && !buyerApproved) || (msg.sender == seller && buyerApproved && !sellerApproved), "Unauthorized or conditions not met");

        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender == arbiter ? seller : buyer).call{value: amount}("");
        require(success, "Failed to release funds");
        fundsReleased = true;
        emit FundsReleased(amount, msg.sender == arbiter ? seller : buyer);
    }

    function refund() public onlyParty escrowActive {
        require((msg.sender == arbiter && (!buyerApproved || !sellerApproved)) || (msg.sender == buyer && !sellerApproved && buyerApproved) || (msg.sender == seller && !buyerApproved && sellerApproved), "Unauthorized or conditions not met");

        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender == arbiter ? buyer : seller).call{value: amount}("");
        require(success, "Failed to refund funds");
        fundsRefunded = true;
        emit FundsRefunded(amount, msg.sender == arbiter ? buyer : seller);
    }

    function expireEscrow() public onlyParty {
        require(block.timestamp >= escrowEndTime && !fundsReleased && !fundsRefunded, "Escrow not yet expired");
        fundsRefunded = true;
        emit EscrowExpired();
    }
}

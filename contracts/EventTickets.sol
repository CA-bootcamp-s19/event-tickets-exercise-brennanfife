pragma solidity ^0.5.0;

contract EventTickets { // Keeps track of the details and ticket sales of one event.
    address payable public owner;
    uint TICKET_PRICE = 100 wei;

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    Event myEvent;

    event LogBuyTickets(address purchaser, uint numberOfTickets); // Provide info about the purchaser and the number of tickets purchased.
    event LogGetRefund(address requester, uint numberofTickets); // Provide info about the refund requester and the number of tickets refunded.
    event LogEndSale(address owner, uint transferedAmount); // Provide info about the contract owner and the balance transferred to them.

    modifier isOwner {
        require(owner == msg.sender, "Caller is not contract owner");
        _;
    }

    modifier checkValue(uint _ticketCount) {
        _; //refund them after pay for item (why it is before, _ checks for logic before func)
        uint _price = TICKET_PRICE*_ticketCount;
        uint amountToRefund = msg.value - _price;
        msg.sender.transfer(amountToRefund);
    }

    constructor(string memory _description, string memory url, uint numberOfTickets) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = url;
        myEvent.totalTickets = numberOfTickets;
        myEvent.isOpen = true;
    }

    function readEvent() public view returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        return (myEvent.description, myEvent.website, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
    }

    function getBuyerTicketCount(address _address) public view returns(uint ticketsPurchased) {
        return myEvent.buyers[_address];
    }

    function buyTickets(uint numberOfTickets) public payable checkValue(numberOfTickets) {
        require(myEvent.isOpen, "Event is not open");
        require(msg.value >= (numberOfTickets * TICKET_PRICE), "Insufficient amount");
        require((myEvent.totalTickets - myEvent.sales) >= numberOfTickets, "Not enough tickets for sale");
        myEvent.buyers[msg.sender] = numberOfTickets;
        myEvent.sales += numberOfTickets;
        emit LogBuyTickets(msg.sender, numberOfTickets);
    }

    function getRefund() public payable {
        require(myEvent.buyers[msg.sender] > 0, "Requester hasn't purchased any tickets");
        uint refundedTickets = myEvent.buyers[msg.sender];
        myEvent.sales -= refundedTickets;
        uint refundedValue = refundedTickets * TICKET_PRICE;
        msg.sender.transfer(refundedValue);
        emit LogGetRefund(msg.sender, refundedTickets);
    }

    function endSale() public isOwner {
        myEvent.isOpen = false;
        uint transferValue = address(this).balance;
        owner.transfer(transferValue);
        emit LogEndSale(owner, transferValue);
    }
}

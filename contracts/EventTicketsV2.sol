pragma solidity ^0.5.0;
contract EventTicketsV2 { // Keeps track of the details and ticket sales of multiple events.
    address payable public owner;
    uint PRICE_TICKET = 100 wei;
    uint public idGenerator;

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance);

    modifier isOwner {
        require(owner == msg.sender, "Caller is not contract owner");
        _;
    }

    modifier verifiedBuyer(address _buyer, uint256 _eventId) {
        require(events[_eventId].buyers[_buyer] > 0, "Buyer has not made a ticket purchase");
        _;
    }

    modifier paidEnough(uint _numberOfTickets) {
        require(msg.value >= _numberOfTickets * PRICE_TICKET, "Insufficient Funds");
        _;
    }

    modifier ticketsLeft(uint _eventId, uint _numberOfTickets) {
        require((events[_eventId].totalTickets - events[_eventId].sales) > _numberOfTickets, "Not enough tickets");
        _;
    }

    modifier isOpen(uint _eventId) {
        require(events[_eventId].isOpen, "Event is not open");
        _;
    }

    modifier checkValue(uint _ticketCount) {
        _; //refund them after pay for item (why it is before, _ checks for logic before func)
        uint _price = PRICE_TICKET * _ticketCount;
        uint amountToRefund = msg.value - _price;
        msg.sender.transfer(amountToRefund);
    }

    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }

    function addEvent(string memory _description, string memory _url, uint _totalTickets) public isOwner {
        Event memory newEvent = Event({description: _description, website: _url, totalTickets: _totalTickets, sales: 0, isOpen: true});
        uint eventId = idGenerator;
        events[eventId] = newEvent;
        idGenerator++;
        emit LogEventAdded(newEvent.description, newEvent.website, newEvent.totalTickets, eventId);
    }

    function readEvent(uint _eventId) public view
    returns(string memory description, string memory url, uint totalTickets, uint sales, bool isOpen) {
        return(events[_eventId].description, events[_eventId].website, events[_eventId].totalTickets,
                events[_eventId].sales, events[_eventId].isOpen);
    }

    function buyTickets(uint _eventId, uint _numberOfTickets) public payable
        isOpen(_eventId) paidEnough(_numberOfTickets) ticketsLeft(_eventId, _numberOfTickets) checkValue(_numberOfTickets) {
        events[_eventId].buyers[msg.sender] += _numberOfTickets;
        events[_eventId].sales += _numberOfTickets;
        emit LogBuyTickets(msg.sender, _eventId, _numberOfTickets);
    }

    function getRefund(uint _eventId) public payable verifiedBuyer(msg.sender, _eventId) isOpen(_eventId) {
        uint numOfTickets = events[_eventId].buyers[msg.sender];
        uint refundValue = numOfTickets * PRICE_TICKET;
        events[_eventId].sales -= numOfTickets;
        msg.sender.transfer(refundValue);
        emit LogGetRefund(msg.sender, _eventId, numOfTickets);
    }

    function getBuyerNumberTickets(uint _eventId) public view verifiedBuyer(msg.sender, _eventId) returns(uint _numberOfTickets) {
        return events[_eventId].buyers[msg.sender];
    }

    function endSale(uint _eventId) public isOwner {
        events[_eventId].isOpen = false;
        uint valueTransfer = events[_eventId].sales * PRICE_TICKET;
        owner.transfer(valueTransfer);
        emit LogEndSale(owner, valueTransfer);
    }
}

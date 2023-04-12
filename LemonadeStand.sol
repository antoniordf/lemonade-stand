// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

// Define a contract Lemonade stand
contract LemonadeStand {
    // variable: Owner
    address owner;

    // variable: sku count
    uint skuCount;

    // Event: 'state' with value 'ForSale'
    enum State {
        ForSale,
        Sold,
        Shipped
    }

    // Struct: Item - name, sku, price, state, seller, buyer
    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address buyer;
    }

    // Define mapping 'items' that maps an SKU (a number) to an Item
    mapping(uint => Item) items;

    // Events
    event ForSale(uint256 indexed skuCount);
    event Sold(uint256 indexed sku);
    event Shipped(uint256 indexed sku);

    // Modifier: onlyOwner to see if owner == msg.sender
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Define a modifier that verifies the caller
    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    // Define a modifier to check if paid amount is sufficient to cover price
    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    // Define a modifier that checks if an item.state of a sku is ForSale
    modifier forSale(uint _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    // Define a modifier that checks if an item.state of a sku is sold
    modifier sold(uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint _amountToRefund = msg.value - _price;
        payable(items[_sku].buyer).transfer(_amountToRefund);
    }

    constructor() {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint _price) public onlyOwner {
        // Increment sku
        skuCount++;

        // Emit the appropriate event
        emit ForSale(skuCount);

        // Add the new item into inventory and mark it for sale
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: payable(msg.sender),
            buyer: address(0)
        });
    }

    function buyItem(
        uint sku
    ) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
        address buyer = msg.sender;
        uint price = items[sku].price;
        // Update buyer
        items[sku].buyer = buyer;
        // Update state
        items[sku].state = State.Sold;
        // Transfer money to seller
        items[sku].seller.transfer(price);
        // Emit the appropriate event
        emit Sold(sku);
    }

    function fetchItem(
        uint _sku
    )
        public
        view
        returns (
            string memory name,
            uint sku,
            uint price,
            string memory stateIs,
            address seller,
            address buyer
        )
    {
        uint state;
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        if (state == 0) {
            stateIs = "ForSale";
        } else if (state == 1) {
            stateIs = "Sold";
        } else if (state == 2) {
            stateIs = "Shipped";
        }
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
    }

    // Only a sold item can be shipped
    function shipItem(
        uint sku
    ) public sold(sku) verifyCaller(items[sku].seller) {
        // Change the state of the item to 'shipped'
        items[sku].state = State.Shipped;
        // Emit appropriate event
        emit Shipped(sku);
    }
}

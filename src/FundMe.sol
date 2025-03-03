// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/AggregatorV3Interface.sol";

error FundMe_NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant min_USD = 5e18;
    address[] private s_funders;
    address private immutable i_owner;
    mapping(address => uint256) private s_AddToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    constructor (address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConRate(s_priceFeed) >= min_USD, "You need spend more ETH!");
        s_AddToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_AddToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaper_withdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_AddToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function get_add_to_amount_funded(address fundingAddress) public view returns(uint256) {
        return s_AddToAmountFunded[fundingAddress];
    }

    function get_funder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function get_owner() public view returns(address) {
        return i_owner;
    }

    function get_priceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }
    
}
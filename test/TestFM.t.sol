// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployFM} from "../script/DeployFM.s.sol";
import {HelperConfig, CodeConstants} from "../script/HelperConfig.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "./Mock/MockV3Aggregator.sol";

contract TestFM is ZkSyncChainChecker, CodeConstants, StdCheats, Test {

    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployFM deployer = new DeployFM();
            (fundMe, helperConfig) = deployer.deployFM();
        } else {
            MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DEC, IN_PRICE);
            fundMe = new FundMe(address(mockPriceFeed));
        }
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function test_priceFeed_set_currectly() public skipZkSync {
        address retrievedPriceFeed = address(fundMe.get_priceFeed());
        address expectedPriceFeed = helperConfig.getConfigChainId(block.chainid).priceFeed;
        assertEq(retrievedPriceFeed, expectedPriceFeed);
    }

    function test_fund_fails_without_enough_eth() public skipZkSync {
        vm.expectRevert();
        fundMe.fund();
    }

    function test_fund_updates_funded_data_structure() public skipZkSync {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.get_add_to_amount_funded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function test_adds_funder_to_array_of_funders() public skipZkSync {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.get_funder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function test_onlyOwner_can_withdraw() public skipZkSync {
        vm.expectRevert();
        vm.prank(address(3));
        fundMe.withdraw();
    }

    function test_withdraw_from_single_funder() public funded skipZkSync {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.get_owner().balance;

        vm.startPrank(fundMe.get_owner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.get_owner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function test_withdraw_from_multiple_funders() public funded skipZkSync {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.get_owner().balance;

        vm.startPrank(fundMe.get_owner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.get_owner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.get_owner().balance - startingOwnerBalance);
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {DeployFM} from "../script/DeployFM.s.sol";
import {FundFundMe, WithdrawFundMe} from "../script/Interactions.s.sol";
import {FundMe} from "../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract TestInteractions is ZkSyncChainChecker, StdCheats, Test {

    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external skipZkSync {
        if (!isZkSyncChain()) {
            DeployFM deployer = new DeployFM();
            (fundMe, helperConfig) = deployer.deployFM();
        } else {
            helperConfig = new HelperConfig();
            fundMe = new FundMe(helperConfig.getConfigChainId(block.chainid).priceFeed);
        }

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function test_user_can_fund_and_withdraw() public skipZkSync {
        uint256 preUserBalance = address(USER).balance;
        uint256 preOwnerBalance = address(fundMe.get_owner()).balance;

        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(fundMe.get_owner()).balance;

        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
    
}
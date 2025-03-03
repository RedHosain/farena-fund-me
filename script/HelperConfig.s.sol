// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockV3Aggregator} from "../test/Mock/MockV3Aggregator.sol";
import {Script, console2} from "forge-std/Script.sol";

abstract contract CodeConstants {

    uint8 public constant DEC = 8;
    int256 public constant IN_PRICE = 2000e8;

    uint256 public constant ETH_SEP_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAIN_CHAIN_ID = 1;
    uint256 public constant ZKS_SEP_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

}

contract HelperConfig is CodeConstants, Script {

    error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chaibId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEP_CHAIN_ID] = get_sep_eth_config();
        networkConfigs[ZKS_SEP_CHAIN_ID] = get_zks_sep_config();
    }

    function getConfigChainId(uint256 chainId) public returns(NetworkConfig memory) {
        if (networkConfigs[chainId].priceFeed != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return get_or_create_anvil_eth_config();
        } else if (chainId == ETH_MAIN_CHAIN_ID) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function get_sep_eth_config() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function get_zks_sep_config() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
        });
    }

    function get_main_eth_config() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
    }

    function get_or_create_anvil_eth_config() public returns(NetworkConfig memory) {
        if (localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        console2.log("You have deployed a mock contract!");
        console2.log("So fuck you!");
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DEC, IN_PRICE);
        vm.stopBroadcast();


        localNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return localNetworkConfig;
    }
    
}
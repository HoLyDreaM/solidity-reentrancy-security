// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SafeBank} from "../src/SafeBank.sol";

/// @notice Yerel Anvil için SafeBank deploy örneği.
contract DeploySafeBank is Script {
    function run() external returns (SafeBank bank) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        bank = new SafeBank();
        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VulnerableBank} from "../src/VulnerableBank.sol";
import {SafeBank} from "../src/SafeBank.sol";
import {PullPaymentBank} from "../src/PullPaymentBank.sol";
import {Attacker} from "../src/Attacker.sol";

contract ReentrancyTest is Test {
    uint256 internal constant DEPOSIT = 1 ether;

    function test_VulnerableBank_reentrancyDrainsExtraFunds() public {
        VulnerableBank vault = new VulnerableBank();
        Attacker attacker = new Attacker(address(vault));

        address victim = makeAddr("victim");
        vm.deal(victim, DEPOSIT);
        vm.prank(victim);
        vault.deposit{value: DEPOSIT}();

        vm.deal(address(this), DEPOSIT);
        attacker.attack{value: DEPOSIT}();

        assertGt(address(attacker).balance, DEPOSIT, "attacker should drain more than deposit");
        assertLt(vault.totalBalance(), DEPOSIT, "victim funds should be reduced");
    }

    function test_SafeBank_reentrancyFailsAndInvariantsHold() public {
        SafeBank vault = new SafeBank();
        Attacker attacker = new Attacker(address(vault));

        address victim = makeAddr("victim");
        vm.deal(victim, DEPOSIT);
        vm.prank(victim);
        vault.deposit{value: DEPOSIT}();

        vm.deal(address(this), DEPOSIT);
        vm.expectRevert();
        attacker.attack{value: DEPOSIT}();

        assertEq(vault.balances(victim), DEPOSIT);
        assertEq(vault.totalBalance(), DEPOSIT);
        assertEq(address(attacker).balance, 0);
    }

    function test_SafeBank_honestWithdraw() public {
        SafeBank vault = new SafeBank();
        address user = makeAddr("user");

        vm.deal(user, DEPOSIT);
        vm.startPrank(user);
        vault.deposit{value: DEPOSIT}();
        vault.withdraw();
        vm.stopPrank();

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, DEPOSIT);
    }

    function test_PullPaymentBank_queueThenWithdraw() public {
        PullPaymentBank vault = new PullPaymentBank();
        address user = makeAddr("user");

        vm.deal(user, DEPOSIT);
        vm.startPrank(user);
        vault.deposit{value: DEPOSIT}();
        vault.queueWithdrawal();
        assertEq(vault.balances(user), 0);
        assertEq(vault.pendingWithdrawals(user), DEPOSIT);
        vault.withdrawPending();
        vm.stopPrank();

        assertEq(vault.pendingWithdrawals(user), 0);
        assertEq(user.balance, DEPOSIT);
    }
}

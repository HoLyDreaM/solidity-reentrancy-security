// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title PullPaymentBank
/// @notice Ana akışta Ether göndermez; hak edilen tutarı kaydeder, alıcı ayrı işlemle çeker (pull).
contract PullPaymentBank is ReentrancyGuard {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public pendingWithdrawals;

    event Deposited(address indexed account, uint256 amount);
    event WithdrawalQueued(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @dev Dış çağrı yok; yalnızca hak kaydı (reentrancy yüzeyi daralır).
    function queueWithdrawal() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        balances[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += amount;

        emit WithdrawalQueued(msg.sender, amount);
    }

    function withdrawPending() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "nothing pending");

        pendingWithdrawals[msg.sender] = 0;

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

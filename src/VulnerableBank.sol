// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VulnerableBank
/// @notice Eğitim amaçlı güvensiz vault: dış çağrıdan sonra state güncellenir (klasik reentrancy).
/// @dev Üretimde kullanmayın.
contract VulnerableBank {
    mapping(address => uint256) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @dev Interactions → Effects sırası: alıcı receive/fallback ile yeniden girebilir.
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance");

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");

        balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

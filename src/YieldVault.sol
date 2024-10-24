// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DepositAmountMustBeGreaterThanZero();
error WithdrawAmountMustBeGreaterThanZero();
error InsufficientBalance(uint256 available, uint256 requested);

contract YieldVault is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable token;  // The token deposited by users
    mapping(address => uint256) public userBalances;  // Track user balances

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);  // Initialize the token contract
    }

    // Deposit function with Pausable modifier
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
         if (amount == 0) revert DepositAmountMustBeGreaterThanZero(); 

        // Transfer tokens from user to the vault
        token.transferFrom(msg.sender, address(this), amount);

        // Update user balance
        userBalances[msg.sender] += amount;

        // Emit deposit event
        emit Deposit(msg.sender, amount);
    }

    // Withdraw function with Pausable modifier
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert WithdrawAmountMustBeGreaterThanZero();

        uint256 balance = userBalances[msg.sender];
        if (balance < amount) revert InsufficientBalance({available: balance, requested: amount});

        // Update user balance before transfer to prevent reentrancy
        userBalances[msg.sender] -= amount;

        // Transfer tokens back to the user
        token.transfer(msg.sender, amount);

        // Emit withdraw event
        emit Withdraw(msg.sender, amount);
    }

    // Admin function to enable emergency shutdown
    function pause() external onlyOwner {
        _pause();  // Call the OpenZeppelin internal function
    }

    // Admin function to disable emergency shutdown
    function unpause() external onlyOwner {
        _unpause();  // Call the OpenZeppelin internal function
    }
}

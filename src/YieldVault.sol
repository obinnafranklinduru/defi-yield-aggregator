// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Strategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error InvalidStrategyAddress();
error SharesMustBeGreaterThanZero();
error DepositAmountMustBeGreaterThanZero();
error InsufficientBalance(uint256 available, uint256 requested);

contract YieldVault is ERC20, Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable token; // The token this vault accepts (DAI or USDC)

    uint256 public totalAssets; // Track total assets in the vault

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);

    /// @param _token The address of underlying token (DAI or USDC)
    /// @param  _name Name of the vault token ("YieldVault Token")
    /// @param _symbol Symbol of the vault token ("yvDAI")
    constructor(address _token, string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    // Deposit function: Users deposit tokens and receive shares
    function deposit(uint256 amount) external nonReentrant whenNotPaused returns (uint256 shares) {
        if (amount == 0) revert DepositAmountMustBeGreaterThanZero();

        // Calculate shares to mint based on current total assets
        if (totalAssets == 0 || totalSupply() == 0) {
            shares = amount; // 1:1 ratio if no assets are in the vault yet
        } else {
            shares = (amount * totalSupply()) / totalAssets;
        }

        totalAssets += amount; // Increase the total assets
        _mint(msg.sender, shares); // Mint shares to the user

        token.transferFrom(msg.sender, address(this), amount); // Transfer the tokens

        emit Deposited(msg.sender, amount, shares);
        return shares;
    }

    // Withdraw function: Users withdraw by redeeming their shares
    function withdraw(uint256 shares) external nonReentrant whenNotPaused returns (uint256 amount) {
        if (shares == 0) revert SharesMustBeGreaterThanZero();
        if (balanceOf(msg.sender) < shares) {
            revert InsufficientBalance({available: balanceOf(msg.sender), requested: shares});
        }

        // Calculate the amount to return based on current total assets
        amount = (shares * totalAssets) / totalSupply();

        totalAssets -= amount; // Decrease total assets
        _burn(msg.sender, shares); // Burn the user's shares

        token.transfer(msg.sender, amount); // Transfer the underlying tokens back

        emit Withdrawn(msg.sender, shares, amount);
        return amount;
    }

    // Admin function to enable emergency shutdown
    function pause() external onlyOwner {
        _pause(); // Call the OpenZeppelin internal function
    }

    // Admin function to disable emergency shutdown
    function unpause() external onlyOwner {
        _unpause(); // Call the OpenZeppelin internal function
    }
}

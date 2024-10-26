// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStrategy} from "./IStrategy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from  "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error StrategyNotSet();
error InvalidStrategyAddress();
error StrategyCannotBeZeroAddress();
error SharesMustBeGreaterThanZero();
error DepositAmountMustBeGreaterThanZero();
error InsufficientBalance(uint256 available, uint256 requested);

contract YieldVault is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IStrategy public strategy;

    IERC20 public immutable token; // The asset managed by the vault, Supports a configurable ERC-20 token address (WETH or DAI or USDC)

    uint256 public totalAssets; // Track total assets in the vault

    // Events
    event StrategyUpdated(address indexed newStrategy);
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);

    modifier checkStrategySetup {
        if(address(strategy) == address(0) && address(strategy) == address(this)) revert StrategyNotSet();
        _;        
    }

    /// @param _token The address of the underlying token (e.g., WETH, DAI, USDC)
    /// @param _name The name of the YieldVault contract token
    /// @param _symbol The symbol of the YieldVault vault token
    constructor(
        address _token,
        string memory _name,
        string memory _symbol
        ) ERC20(_name, _symbol)  Ownable(msg.sender) {
        token = IERC20(_token);
    }

    /// @notice Deposit assets into the vault and forward them to the strategy
    /// @param amount The amount to deposit
    function deposit(uint256 amount) external nonReentrant whenNotPaused checkStrategySetup returns (uint256 shares) {
        if (amount == 0) revert DepositAmountMustBeGreaterThanZero();

        // Calculate shares to mint based on current total assets
        if (totalAssets == 0 || totalSupply() == 0) {
            shares = amount; // 1:1 ratio if no assets are in the vault yet
        } else {
            shares = (amount * totalSupply()) / totalAssets;
        }

        totalAssets += amount; // Increase the total assets
        _mint(msg.sender, shares); // Mint shares to the user

        // Transfer the tokens of YieldVault, this will be used to withdraw token (e.g., WETH, DAI, USDC)
        // which the user deposited .
        token.safeTransferFrom(msg.sender, address(this), amount); 

        strategy.invest(amount); // Invest in the chosen strategy

        emit Deposited(msg.sender, amount, shares);
        return shares;
    }

    // Withdraw function: Users withdraw by redeeming their shares
    function withdraw(uint256 shares) external nonReentrant whenNotPaused checkStrategySetup returns (uint256 amount) {
        if (shares == 0) revert SharesMustBeGreaterThanZero();

        if (balanceOf(msg.sender) < shares) {
            revert InsufficientBalance({available: balanceOf(msg.sender), requested: shares});
        }

        // Calculate the amount to return based on current total assets
        amount = (shares * totalAssets) / totalSupply();

        totalAssets -= amount; // Decrease total assets
        _burn(msg.sender, shares); // Burn the user's shares

        // Withdraw assets from the strategy back to the vault
        strategy.withdraw(amount);

        // Transfer the underlying tokens back
        (bool success, ) = address(token).call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success, "Transfer to user failed");

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

    /// Set the strategy
    /// @param _strategy The address of the strategy contract that determines the yield farming protocol
    function setStrategy(address _strategy) external onlyOwner {
        if(_strategy == address(0)) revert StrategyCannotBeZeroAddress();
        strategy = IStrategy(_strategy);

        emit StrategyUpdated(address(strategy));
    }
}

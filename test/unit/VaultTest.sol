// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockToken} from "../mocks/MockToken.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {MockPool, MockPoolAddressesProvider} from "../mocks/MockPool.sol";
import {YieldVault} from "../../src/YieldVault.sol";
import {AaveStrategy} from "../../src/AaveStrategy.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

// Mock ERC20 token to simulate deposits and withdrawals
contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1_000_000 * 1e18); // Mint a large supply for testing
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract YieldVaultTest is Test {
    YieldVault public yieldVault;
    AaveStrategy public aaveStrategy;
    MockERC20 public mockToken;
    MockPool public mockPool;
    MockPoolAddressesProvider public mockProvider;
    IPool provider;

    address aaveV3PoolAddress;

    address owner = address(this);
    address user = makeAddr("user");

    function setUp() public {
        // Deploy a mock ERC20 token
        mockToken = new MockERC20();

        // Deploy the mock provider
        mockProvider = new MockPoolAddressesProvider();

        // Deploy the mock Aave pool
        // mockPool = new MockPool(IPoolAddressesProvider(mockProvider));

        // provider = new MockPool(IPoolAddressesProvider(aaveV3PoolAddress));

        // Deploy YieldVault with the mock token
        yieldVault = new YieldVault(address(mockToken), "Yield Vault Token", "YVT");

        // Deploy AaveStrategy with the mock token, the YieldVault, and the mock provider
        aaveStrategy = new AaveStrategy(address(mockToken), address(yieldVault), address(mockProvider));

        // Set the strategy in the vault
        yieldVault.setStrategy(address(aaveStrategy));

        // Deal tokens to the user for testing
        mockToken.mint(user, 1_000 * 1e18);
    }

    // Test: User deposits ERC-20 tokens into the vault
    function testDepositERC20() public {
        vm.startPrank(user);

        uint256 depositAmount = 100 * 1e18;

        // Approve YieldVault to pull tokens before deposit
        mockToken.approve(address(yieldVault), depositAmount);

        // Verify the allowance between YieldVault and AaveStrategy
        uint256 allowance = mockToken.allowance(address(yieldVault), address(aaveStrategy));
        console.log("Allowance:", allowance); // Should be max allowance if set correctly in YieldVault

        // Capture initial total assets and user's share balance for verification
        uint256 initialTotalAssets = yieldVault.totalAssets();
        uint256 initialUserShares = yieldVault.balanceOf(user);

        // Test the deposit function
        uint256 shares = yieldVault.deposit(depositAmount);

        // Assertions
        assertEq(
            yieldVault.totalAssets(),
            initialTotalAssets + depositAmount,
            "Total assets should increase by deposit amount"
        );
        assertEq(yieldVault.balanceOf(user), initialUserShares + shares, "User should receive corresponding shares");

        vm.stopPrank();
    }

    // // Test: Depositing without prior approval should revert
    // function testDepositFailsWithoutApproval() public {
    //     vm.startPrank(user);

    //     uint256 depositAmount = 100 * 1e18;

    //     // Attempt deposit without approval, should revert
    //     vm.expectRevert("ERC20: insufficient allowance");
    //     yieldVault.deposit(depositAmount);

    //     vm.stopPrank();
    // }

    // // Test: Withdraw function with valid shares
    // function testWithdraw() public {
    //     vm.startPrank(user);

    //     uint256 depositAmount = 100 * 1e18;
    //     mockToken.approve(address(yieldVault), depositAmount);

    //     // Deposit tokens and capture the shares issued
    //     uint256 shares = yieldVault.deposit(depositAmount);

    //     // Withdraw tokens by redeeming the shares
    //     uint256 initialTotalAssets = yieldVault.totalAssets();
    //     uint256 amountWithdrawn = yieldVault.withdraw(shares);

    //     // Assertions
    //     assertEq(yieldVault.totalAssets(), initialTotalAssets - amountWithdrawn, "Total assets should decrease by withdrawn amount");
    //     assertEq(mockToken.balanceOf(user), amountWithdrawn, "User should receive the correct amount withdrawn");

    //     vm.stopPrank();
    // }

    // // Test: Attempting to withdraw without shares should revert
    // function testWithdrawFailsWithZeroShares() public {
    //     vm.startPrank(user);

    //     // Attempt to withdraw without depositing
    //     vm.expectRevert(SharesMustBeGreaterThanZero.selector);
    //     yieldVault.withdraw(0);

    //     vm.stopPrank();
    // }

    // // Test: Set and verify strategy in the vault
    // function testSetStrategy() public {
    //     address newStrategy = address(aaveStrategy);

    //     // Set the strategy and capture the event
    //     yieldVault.setStrategy(newStrategy);

    //     // Assertion to confirm strategy was set
    //     assertEq(address(yieldVault.strategy()), newStrategy, "Strategy should be updated successfully");
    // }
}

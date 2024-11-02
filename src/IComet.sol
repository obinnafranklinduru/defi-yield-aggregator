// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IComet {
    error Absurd();
    error AlreadyInitialized();
    error BadAmount();
    error BadAsset();
    error BadDecimals();
    error BadDiscount();
    error BadMinimum();
    error BadNonce();
    error BadPrice();
    error BadSignatory();
    error BorrowCFTooLarge();
    error BorrowTooSmall();
    error InsufficientReserves();
    error InvalidInt104();
    error InvalidInt256();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidUInt64();
    error InvalidValueS();
    error InvalidValueV();
    error LiquidateCFTooLarge();
    error NegativeNumber();
    error NoSelfTransfer();
    error NotCollateralized();
    error NotForSale();
    error NotLiquidatable();
    error Paused();
    error SignatureExpired();
    error SupplyCapExceeded();
    error TimestampTooLarge();
    error TooManyAssets();
    error TooMuchSlippage();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();

    event AbsorbCollateral(
        address indexed absorber,
        address indexed borrower,
        address indexed asset,
        uint256 collateralAbsorbed,
        uint256 usdValue
    );
    event AbsorbDebt(address indexed absorber, address indexed borrower, uint256 basePaidOut, uint256 usdValue);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BuyCollateral(address indexed buyer, address indexed asset, uint256 baseAmount, uint256 collateralAmount);
    event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);
    event Supply(address indexed from, address indexed dst, uint256 amount);
    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint256 amount);
    event Withdraw(address indexed src, address indexed to, uint256 amount);
    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint256 amount);
    event WithdrawReserves(address indexed to, uint256 amount);

    function absorb(address absorber, address[] memory accounts) external;

    function accrueAccount(address account) external;

    function allow(address manager, bool isAllowed) external;

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveThis(address manager, address asset, uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseAccrualScale() external view returns (uint64);

    function baseBorrowMin() external view returns (uint256);

    function baseIndexScale() external view returns (uint64);

    function baseMinForRewards() external view returns (uint256);

    function baseScale() external view returns (uint256);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function baseTrackingAccrued(address account) external view returns (uint64);

    function baseTrackingBorrowSpeed() external view returns (uint256);

    function baseTrackingSupplySpeed() external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function borrowKink() external view returns (uint256);

    function borrowPerSecondInterestRateBase() external view returns (uint256);

    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint256);

    function borrowPerSecondInterestRateSlopeLow() external view returns (uint256);

    function buyCollateral(address asset, uint256 minAmount, uint256 baseAmount, address recipient) external;

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function decimals() external view returns (uint8);

    function extensionDelegate() external view returns (address);

    function factorScale() external view returns (uint64);

    function getAssetInfo(uint8 i) external view returns (CometCore.AssetInfo memory);

    function getAssetInfoByAddress(address asset) external view returns (CometCore.AssetInfo memory);

    function getBorrowRate(uint256 utilization) external view returns (uint64);

    function getCollateralReserves(address asset) external view returns (uint256);

    function getPrice(address priceFeed) external view returns (uint256);

    function getReserves() external view returns (int256);

    function getSupplyRate(uint256 utilization) external view returns (uint64);

    function getUtilization() external view returns (uint256);

    function governor() external view returns (address);

    function hasPermission(address owner, address manager) external view returns (bool);

    function initializeStorage() external;

    function isAbsorbPaused() external view returns (bool);

    function isAllowed(address, address) external view returns (bool);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function liquidatorPoints(address)
        external
        view
        returns (uint32 numAbsorbs, uint64 numAbsorbed, uint128 approxSpend, uint32 _reserved);

    function maxAssets() external view returns (uint8);

    function name() external view returns (string memory);

    function numAssets() external view returns (uint8);

    function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused)
        external;

    function pauseGuardian() external view returns (address);

    function priceScale() external view returns (uint64);

    function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

    function storeFrontPriceFactor() external view returns (uint256);

    function supply(address asset, uint256 amount) external;

    function supplyFrom(address from, address dst, address asset, uint256 amount) external;

    function supplyKink() external view returns (uint256);

    function supplyPerSecondInterestRateBase() external view returns (uint256);

    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint256);

    function supplyPerSecondInterestRateSlopeLow() external view returns (uint256);

    function supplyTo(address dst, address asset, uint256 amount) external;

    function symbol() external view returns (string memory);

    function targetReserves() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalsBasic() external view returns (CometStorage.TotalsBasic memory);

    function totalsCollateral(address) external view returns (uint128 totalSupplyAsset, uint128 _reserved);

    function trackingIndexScale() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferAsset(address dst, address asset, uint256 amount) external;

    function transferAssetFrom(address src, address dst, address asset, uint256 amount) external;

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function userBasic(address)
        external
        view
        returns (
            int104 principal,
            uint64 baseTrackingIndex,
            uint64 baseTrackingAccrued,
            uint16 assetsIn,
            uint8 _reserved
        );

    function userCollateral(address, address) external view returns (uint128 balance, uint128 _reserved);

    function userNonce(address) external view returns (uint256);

    function version() external view returns (string memory);

    function withdraw(address asset, uint256 amount) external;

    function withdrawFrom(address src, address to, address asset, uint256 amount) external;

    function withdrawReserves(address to, uint256 amount) external;

    function withdrawTo(address to, address asset, uint256 amount) external;
}

interface CometCore {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }
}

interface CometStorage {
    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }
}

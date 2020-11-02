pragma solidity ^0.6.7;

struct CollateralOpts {
        bytes32 ilk;
        address gem;
        address join;
        address flip;
        address pip;
        bool    isLiquidatable;
        bool    isOSM;
        bool    whitelistOSM;
        uint256 ilkDebtCeiling;
        uint256 minVaultAmount;
        uint256 maxLiquidationAmount;
        uint256 liquidationPenalty;
        uint256 ilkStabilityFee;
        uint256 bidIncrease;
        uint256 bidDuration;
        uint256 auctionDuration;
        uint256 liquidationRatio;
    }

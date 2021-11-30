pragma solidity ^0.6.12;

struct CollateralOpts {
    bytes32 ilk;                      // bytes32 result of the hyphenated, all caps token vault name (e.g. "WBTC-C")
    address gem;                      // address of the particular underlying token (e.g. WBTC), usually found already in the latest changelog.makerdao.com releases
    address join;                     // address of deployed GemJoin
    address clip;                     // address of auction Clip
    address calc;                     // address of auction price discovery curve, "Auction Price Function (calc)" gov proposal parameter
    address pip;                      // address of the collateral price feed oracle to be used
    bool isLiquidatable;              // true if collateral can be liquidated
    bool isOSM;                       // true if there's an OSM contract being used for the price feed
    bool whitelistOSM;                // true if there's the need to whitelist an OSM contract being onboarded to the Maker Protocol
    uint256 ilkDebtCeiling;           // maximum amount of DAI able to be minted from a given vault collectively, "Debt Ceiling (line)" gov proposal parameter
    uint256 minVaultAmount;           // minimum amount of DAI a particular user can generate from a given vault, "Debt Floor (dust)" gov proposal parameter
    uint256 maxLiquidationAmount;     // maximum amount of DAI debt for which collateral auctions can be active at any one time within a particular vault type, "Local Liquidation Limit (ilk.hole)" gov proposal parameter
    uint256 liquidationPenalty;       // basis point percentage of the liquidation penalty fee, "Liquidation Penalty (chop)" gov proposal parameter
    uint256 ilkStabilityFee;          // per-second-rate conversion obtained from the yearly "Stability Fee" gov proposal parameter
    uint256 startingPriceFactor;      // basis point price multiplier of how much higher than the oracle price auction starts at, "Auction Price Multiplier (buf)" gov proposal parameter
    uint256 breakerTolerance;         // basis point multiplier of how large of a price drop is tolerated before liquidations are paused, "Breaker Price Tolerance (tolerance)" gov proposal parameter
    uint256 auctionDuration;          // time unit, "Maximum Auction Duration (tail)" gov proposal parameter
    uint256 permittedDrop;            // basis point of the maximum percentage drop in collateral price during a collateral auction before the auction is reset, "Maximum Auction Drawdown (cusp)" gov proposal parameter
    uint256 liquidationRatio;         // maximum amount of DAI debt that a vault user can draw from their vault given the value of their collateral locked in that vault, "Liquidation Ratio" gov proposal parameter
    uint256 kprFlatReward;            // flat DAI reward a keeper receives for triggering liquidations (to compensate for gas costs), "Flat Kick Incentive (tip)" gov proposal parameter
    uint256 kprPctReward;             // basis point percentual reward keeper receive from liquidations, "Proportional Kick Incentive (chip)" gov proposal parameter
}

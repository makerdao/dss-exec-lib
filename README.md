# DSS Exec Library

A library for crafting spells in DSS more efficiently, predictably, and easily.

## Public Library Addresses

(v0.0.0) Kovan: TBD

(v0.0.0) Mainnet: TBD

## Requirements

* [Dapptools](https://github.com/dapphub/dapptools)

## About

Provides a list of functions to call to perform commonly used actions in spells in DSS.

Here is an example of a `SpellAction.sol` file that uses the deployed library (from `spells-mainnet` repo):

```js
import {DssAction} from "lib/dss-exec-lib/src/DssAction.sol";

contract SpellAction is DssAction {

    // This can be hardcoded away later or can use the chain-log
    constructor(address lib) DssAction(lib) public {}

    uint256 constant MILLION  = 10 ** 6;

    function execute() external {
        setGlobalDebtCeiling(1500 * MILLION);
        setIlkDebtCeiling("ETH-A", 10 * MILLION);
    }
}
```

The `SpellAction.sol` file must always inherit `DssAction` from `lib/dss-exec-lib`.

The spell itself is deployed as follows:

```js
new DssExec(
    "A test dss exec spell",           // Description
    now + 30 days,                     // Expiration
    true,                              // OfficeHours enabled
    address(new SpellAction(execlib))
);
```

## Actions

Below is an outline of all functions used in the library.

### Authorizations
- `authorize(address _base, address _ward)`: Give an address authorization to perform auth actions on the contract.
- `deauthorize(address _base, address _ward)`: Revoke contract authorization from an address.

### Accumulating Rates
- `accumulateDSR()`: Update rate accumulation for the Dai Savings Rate (DSR).
- `accumulateCollateralStabilityFees(bytes32 _ilk)`: Update rate accumulation for the stability fees of a given collateral type.

### Price Updates
- `updateCollateralPrice(bytes32 _ilk)`: Update price of a given collateral type.

### System Configuration
- `setContract(address _base, bytes32 _what, address _addr)`: Set a contract in another contract, defining the relationship (ex. set a new Cat contract in the Vat)
- `setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr)`: Set a contract in another contract, defining the relationship for a given ilk.

### System Risk Parameters
- `setGlobalDebtCeiling(uint256 _amount)`: Set the global debt ceiling. Amount will be converted to the correct internal precision.
- `setDSR(uint256 _rate)`: Set the Dai Savings Rate.
- `setSurplusAuctionAmount(uint256 _amount)`: Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
- `setSurplusBuffer(uint256 _amount)`: Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
- `setMinSurplusAuctionBidIncrease(uint256 _pct_bps)`: Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
- `setSurplusAuctionBidDuration(uint256 _length)`: Set bid duration for surplus auctions.
- `setSurplusAuctionDuration(uint256 _length)`: Set total auction duration for surplus auctions.
- `setDebtAuctionDelay(uint256 _length)`: Set the number of seconds that pass before system debt is auctioned for MKR tokens.
- `setDebtAuctionDAIAmount(uint256 _amount)`: Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
- `setDebtAuctionMKRAmount(uint256 _amount)`: Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
- `setMinDebtAuctionBidIncrease(uint256 _pct_bps)`: Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
- `setDebtAuctionBidDuration(uint256 _length)`: Set bid duration for debt auctions.
- `setDebtAuctionDuration(uint256 _length)`: Set total auction duration for debt auctions.
- `setDebtAuctionMKRIncreaseRate(uint256 _pct_bps)`: Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision. MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR).
- `setMaxTotalDAILiquidationAmount(uint256 _amount)`: Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
- `setEmergencyShutdownProcessingTime(uint256 _length)`: Set the length of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
- `setGlobalStabilityFee(uint256 _rate)`: Set the global stability fee (not typically used, currently is 0).
- `setDAIReferenceValue(uint256 _amount) `: Set the value of DAI in the reference asset (e.g. $1 per DAI). Amount will be converted to the correct internal precision.

### Collateral Management
- `setIlkDebtCeiling(bytes32 _ilk, uint256 _amount)`: Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
- `setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount)`: Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
- `setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps)`: Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
- `setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount)`: Set max DAI amount for liquidation per vault for a collateral type. Amount will be converted to the correct internal precision.
- `setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps)`: Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
- `setIlkMinAuctionBidIncrease(bytes32 _ilk, uint256 _pct_bps)`: Set minimum bid increase for collateral. Amount will be converted to the correct internal precision.
- `setIlkBidDuration(bytes32 _ilk, uint256 _length)`: Set bid duration for a collateral type.
- `setIlkAuctionDuration(bytes32 _ilk, uint256 _length)`: Set auction duration for a collateral type.
- `setIlkStabilityFee(bytes32 _ilk, uint256 _rate)`: Set the stability fee for a given ilk.

### Core Management
- `updateCollateralAuctionContract(bytes32 _ilk, address _newFlip, address _oldFlip)`: Update collateral auction contracts.
- `updateSurplusAuctionContract(address _newFlap, address _oldFlap)`: Update surplus auction contracts.
- `updateDebtAuctionContract(address _newFlop, address _oldFlop)`: Update debt auction contracts.

### Oracle Management
- `addWritersToMedianWhitelist(address _median, address[] memory _feeds)`: Adds oracle feeds to the Median's writer whitelist, allowing the feeds to write prices.
- `removeWritersFromMedianWhitelist(address _median, address[] memory _feeds)`: Removes oracle feeds to the Median's writer whitelist, disallowing the feeds to write prices.
- `function addReadersToMedianWhitelist(address _median, address[] memory _readers)`: Adds addresses to the Median's reader whitelist, allowing the addresses to read prices from the median.
- `addReaderToMedianWhitelist(address _median, address _reader)`: Adds an address to the Median's reader whitelist, allowing the address to read prices from the median.
- `removeReadersFromMedianWhitelist(address _median, address[] memory _readers)`: Removes addresses from the Median's reader whitelist, disallowing the addresses to read prices from the median.
- `removeReaderFromMedianWhitelist(address _median, address _reader)`: Removes an address to the Median's reader whitelist, disallowing the address to read prices from the median.
- `setMedianWritersQuorum(address _median, uint256 _minQuorum)`: Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
- `addReaderToOSMWhitelist(address _osm, address _reader)`: Adds an address to the Median's reader whitelist, allowing the address to read prices from the OSM.
- `removeReaderFromOSMWhitelist(address _osm, address _reader)`: Removes an address to the Median's reader whitelist, disallowing the address to read prices from the OSM.
- `allowOSMFreeze(address _osm, bytes32 _ilk)`: Add OSM address to OSM mom, allowing it to be frozen by governance.

### Collateral Onboarding
```
function addNewCollateral(
    bytes32          _ilk,
    address[] memory _addresses,
    bool             _liquidatable,
    bool[] memory    _oracleSettings,
    uint256          _ilkDebtCeiling,
    uint256          _minVaultAmount,
    uint256          _maxLiquidationAmount,
    uint256          _liquidationPenalty,
    uint256          _ilkStabilityFee,
    uint256          _bidIncrease,
    uint256          _bidDuration,
    uint256          _auctionDuration,
    uint256          _liquidationRatio
)
```
- Adds new collateral to MCD following standard collateral onboarding procedure.
- `_ilk`:                  Collateral type
- `_addresses`:            Array of contract addresses: [tokenAddress, join, flip, pip]
- `_liquidatable`:         Boolean indicating whether liquidations are enabled for collateral
- `_oracleSettings`:       Boolean array indicating whether: [pip address used is an OSM contract, median is src in osm]
- `_ilkDebtCeiling`:       Debt ceiling for new collateral
- `_minVaultAmount`:       Minimum DAI vault amount required for new collateral
- `_maxLiquidationAmount`: Max DAI amount per vault for liquidation for new collateral
- `_liquidationPenalty`:   Percent liquidation penalty for new collateral [ex. 13.5% == 13500]
- `_ilkStabilityFee`:      Percent stability fee for new collateral       [ex. 4% == 1000000001243680656318820312]
- `_bidIncrease`:          Percent bid increase for new collateral        [ex. 13.5% == 13500]
- `_bidDuration`:          Bid period duration for new collateral
- `_auctionDuration`:      Total auction duration for new collateral
- `_liquidationRatio`:     Percent liquidation ratio for new collateral   [ex. 150% == 150000]


## Testing

```
$ dapp update
$ make test
```

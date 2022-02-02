# DSS Exec Library
![Build Status](https://github.com/makerdao/dss-exec-lib/actions/workflows/.github/workflows/tests.yaml/badge.svg?branch=master)

A library for crafting spells in DSS more efficiently, predictably, and easily.

## Public Library Addresses

- (v0.0.9) Mainnet: [0x8de6ddbcd5053d32292aaa0d2105a32d108484a6](https://etherscan.io/address/0x8de6ddbcd5053d32292aaa0d2105a32d108484a6#code)
- (v0.0.9) Goerli: [0x122f6c0dcd898b4a07310e92c3eae5d7ce0c8bb6](https://goerli.etherscan.io/address/0x122f6c0dcd898b4a07310e92c3eae5d7ce0c8bb6#code)
- (v0.0.9) Kovan: [0xb1d60194ec975bc83f0300b7669a0803b6dd2955](https://kovan.etherscan.io/address/0xb1d60194ec975bc83f0300b7669a0803b6dd2955#code)

## Requirements

* [Dapptools](https://github.com/dapphub/dapptools)

## About

Provides a list of functions to call to perform commonly used actions in spells in DSS.

Here is an example of a `SpellAction.sol` file that uses the deployed library (from `spells-mainnet` repo):

```js
import {DssAction} from "lib/dss-exec-lib/src/DssAction.sol";

contract SpellAction is DssAction {

    constructor(address lib, bool officeHours) DssAction(lib, officeHours) public {}

    uint256 constant MILLION  = 10 ** 6;

    function actions() public override {
        setGlobalDebtCeiling(1500 * MILLION);
        setIlkDebtCeiling("ETH-A", 10 * MILLION);
    }
}
```

The `SpellAction.sol` file must always inherit `DssAction` from `lib/dss-exec-lib`.

The developer must override the `actions()` function and place all spell actions within. This is called by the `execute()` function in the pause, which is subject to an optional limiter for office hours.

*Note:* All variables within the SpellAction MUST be defined as constants, or assigned at runtime inside of the `actions()` function. Variable memory storage is not available within a Spell Action due to the underlying delegatecall mechanisms.

The spell itself is deployed as follows:

```js
new DssExec(
    "A test dss exec spell",      // Description
    now + 30 days,                // Expiration
    address(new SpellAction())
);
```

## Variables and Precision

Below is an outline of how all variables are accounted for for precision based on name.

**NOTE: `DSSExecLib.sol` has NatSpec comments above every function definition that provides a comprehensive definition of the function, its parameters, and any precision calculations that are made.**

- `amount`: Integer amount, (e.g., 10m DAI amount == 10000000)
- `rate`: Rate value expressed as value corresponding to percent from this [list](https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW) (e.g., 4% => 1000000001243680656318820312)
- `duration`: Time, in seconds.
- `pct_bps`: Percentage, in basis points (e.g., 5% = 5 * 100 = 500).
- `value`: Decimal value, expressed as 1000x (e.g., $1.025 == 1025)

## Actions

Below is an outline of all functions used in the library.

### Core Address Helpers
- `dai()`: Dai ERC20 Contract
- `mkr()`: MKR ERC20 Contract
- `vat()`: MCD Core Accounting
- `cat()`: MCD Liquidation Agent
- `dog()`: MCD Liquidation 2.0 Agent
- `jug()`: MCD Rates Module
- `pot()`: MCD Savings Rates Module
- `vow()`: MCD System Stabilizer Module
- `end()`: MCD Shutdown Coordinator
- `reg()`: Ilk Registry
- `spotter()`: MCD Oracle Liason
- `flap()`: MCD Surplus Auction Module
- `flop()`: MCD Debt Auction Module
- `osmMom()`: OSM Circuit Breaker
- `govGuard()`: MKR Authority
- `flipperMom()`: Flipper Governance Interface
- `clipperMom()`: Clipper Governance Interface (Liquidations 2.0)
- `pauseProxy()`: Governance Authority
- `autoLine()`: Debt Ceiling Auto Adjustment
- `daiJoin()`: MCD Join adapter for Dai
- `flip(bytes32 _ilk)`: Collateral Auction Module (per ilk)
- `clip(bytes32 _ilk)`: Collateral Auction Module (per ilk)

### Changelog Management
- `getChangelogAddress(bytes32 _key)`: Get MCD address from key from MCD on-chain changelog.
- `setChangelogAddress(bytes32 _key, address _val)`: Set an address in the MCD on-chain changelog.
- `setChangelogVersion(string memory _version)`: Set version in the MCD on-chain changelog.
- `setChangelogIPFS(string memory _ipfsHash)`: Set IPFS hash of IPFS changelog in MCD on-chain changelog.
- `setChangelogSHA256(string memory _SHA256Sum)`: Set SHA256 hash in MCD on-chain changelog.

### Authorizations
- `authorize(address _base, address _ward)`: Give an address authorization to perform auth actions on the contract.
- `deauthorize(address _base, address _ward)`: Revoke contract authorization from an address.
- `setAuthority(address _base, address _authority)`: Give an address authority to a base contract using authority pattern.
- `delegateVat(address _usr)`: Delegate vat authority to the specified address.
- `undelegateVat(address _usr)`: Revoke vat authority to the specified address.

### Time Management
- `canCast(uint40 _ts, bool _officeHours) returns (bool)`: Use to determine whether a timestamp is within the office hours window.
- `nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) returns (uint256)`: Use to return the timestamp of the first available time after eta that a spell can be cast.

### Accumulating Rates
- `accumulateDSR()`: Update rate accumulation for the Dai Savings Rate (DSR).
- `accumulateCollateralStabilityFees(bytes32 _ilk)`: Update rate accumulation for the stability fees of a given collateral type.

### Price Updates
- `updateCollateralPrice(bytes32 _ilk)`: Update price of a given collateral type.

### System Configuration
- `setContract(address _base, bytes32 _what, address _addr)`: Set a contract in another contract, defining the relationship (ex. set a new Vow contract in the Dog)
- `setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr)`: Set a contract in another contract, defining the relationship for a given ilk.

### System Risk Parameters
- `setGlobalDebtCeiling(uint256 _amount)`: Set the global debt ceiling.
- `increaseGlobalDebtCeiling(uint256 _amount)`: Increase the global debt ceiling.
- `decreaseGlobalDebtCeiling(uint256 _amount)`: Decrease the global debt ceiling.
- `setDSR(uint256 _rate, bool _doDrip)`: Set the Dai Savings Rate.
- `setSurplusAuctionAmount(uint256 _amount)`: Set the DAI amount for system surplus auctions.
- `setSurplusBuffer(uint256 _amount)`: Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start.
- `setMinSurplusAuctionBidIncrease(uint256 _pct_bps)`: Set minimum bid increase for surplus auctions.
- `setSurplusAuctionBidDuration(uint256 _length)`: Set bid duration for surplus auctions.
- `setSurplusAuctionDuration(uint256 _length)`: Set total auction duration for surplus auctions.
- `setDebtAuctionDelay(uint256 _length)`: Set the number of seconds that pass before system debt is auctioned for MKR tokens.
- `setDebtAuctionDAIAmount(uint256 _amount)`: Set the DAI amount for system debt to be covered by each debt auction.
- `setDebtAuctionMKRAmount(uint256 _amount)`: Set the starting MKR amount to be auctioned off to cover system debt in debt auctions.
- `setMinDebtAuctionBidIncrease(uint256 _pct_bps)`: Set minimum bid increase for debt auctions.
- `setDebtAuctionBidDuration(uint256 _length)`: Set bid duration for debt auctions.
- `setDebtAuctionDuration(uint256 _length)`: Set total auction duration for debt auctions.
- `setDebtAuctionMKRIncreaseRate(uint256 _pct_bps)`: Set the rate of increasing amount of MKR out for auction during debt auctions.  MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR).
- `setMaxTotalDAILiquidationAmount(uint256 _amount)`: Set the maximum total DAI amount that can be out for liquidation in the system at any point.
- `setEmergencyShutdownProcessingTime(uint256 _length)`: Set the length of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
- `setGlobalStabilityFee(uint256 _rate)`: Set the global stability fee (not typically used, currently is 0).
- `setDAIReferenceValue(uint256 _amount) `: Set the value of DAI in the reference asset (e.g. $1 per DAI).

### Collateral Management
- `setIlkDebtCeiling(bytes32 _ilk, uint256 _amount)`: Set a collateral debt ceiling.
- `increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global)`: Raise the debt ceiling of a particular ilk.
- `decreaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global)`: Lower the debt ceiling of a particular ilk.
- `setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl)`: Configure the parameters for the Debt Ceiling auto line module for a particluar ilk.
- `setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount)`: Adjust the debt ceiling in the auto line module.
- `removeIlkFromAutoLine(bytes32 _ilk)`: Remove the management of an ilk by the debt ceiling auto line module.
- `setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount)`: Set a collateral minimum vault amount.
- `setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps)`: Set a collateral liquidation penalty.
- `setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount)`: Set max DAI amount for liquidation per vault for a collateral type.
- `setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps)`: Set a collateral liquidation ratio.
- `setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps)`: Set an auction starting price modifier.
- `setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration)`: Set the amount of time permitted before an auction can be reset.
- `setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps)`: Set the percentage amount that an auction can drop in price before it is reset.
- `setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps)`: Sets the percentage of an auction amount that can be paid to keepers.
- `setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) `: Set a flat amount of Dai that will be paid to a keeper for kicking an auction.
- `setLiquidationBreakerPriceTolerance(address _clip, uint256 _pct_bps)`: Set the tolerance for the liquidation circuit-breaker in the clipper IAM.
- `setIlkStabilityFee(bytes32 _ilk, uint256 _rate)`: Set the stability fee for a given ilk.

### Abacus Management
- `initLinearDecrease(address _calc, uint256 _duration)`: Initialize the variables in a LinearDecrease calculator.
- `initStairstepExponentialDecrease(address _calc, uint256 _duration, uint256 _pct_bps)`: Initialize the variables in a StairstepExponentialDecrease calculator.
- `initExponentialDecrease(address _calc, uint256 _pct_bps)`: Initialize the variables in an ExponentialDecrease calculator.

### Oracle Management
- `whitelistOracleMedians(address _oracle)`: Pass an OSM or UNIV2LP oracle to enable it to read the underlying medianizer.
- `addReaderToWhitelist(address _oracle, address _reader)`: Adds an address to the OSM or Median's reader whitelist, allowing the address to read prices.
- `removeReaderFromWhitelist(address _oracle, address _reader)`: Removes an address to the OSM or Median's reader whitelist, disallowing the address to read prices.
- `addReaderToWhitelistCall(address _oracle, address _reader)`: Adds an address to the OSM or Median's reader whitelist, allowing the address to read prices.
- `removeReaderFromWhitelistCall(address _oracle, address _reader)`: Removes an address to the OSM or Median's reader whitelist, disallowing the address to read prices.
- `setMedianWritersQuorum(address _median, uint256 _minQuorum)`: Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
- `allowOSMFreeze(address _osm, bytes32 _ilk)`: Add OSM address to OSM mom, allowing it to be frozen by governance.

### Direct Deposit Module
- `setD3MTargetInterestRate(address _d3m, uint256 _pct_bps)`: Set the target rate (`bar`) for a D3M module.

### Collateral Onboarding
In order to onboard new collateral to the Maker protocol, the following must be done before the spell is prepared:
- Deploy a GemJoin contract
    - Rely the `MCD_PAUSE_PROXY` address
    - Deny the deployer address
- Deploy a Clip contract
    - Rely the `MCD_PAUSE_PROXY` address
    - Deny the deployer address
- Deploy an Abacus pricing contract
    - Initialize values (or use initialization function in DssExecLib)
    - Rely the `MCD_PAUSE_PROXY` address
    - Deny the deployer address
- Deploy a Pip contract (oracles team-managed)
    - Rely the `MCD_PAUSE_PROXY` address
    - Deny the deployer address

Once these actions are done, add the following code (below is an example) to the `execute()` function in the spell. The `setChangelogAddress` function calls are required to add the collateral to the on-chain changelog. They must follow the following convention:
- GEM: `TOKEN`
- JOIN: `MCD_JOIN_TOKEN`
- CLIP: `MCD_CLIP_TOKEN`
- CALC: `MCD_CLIP_CALC_TOKEN`
- PIP: `PIP_TOKEN`

```js
import "src/CollateralOpts.sol";

// Initialize the pricing function with the appropriate initializer
address xmpl_calc = 0x1f206d7916Fd3B1b5B0Ce53d5Cab11FCebc124DA;
DssExecLib.initStairstepExponentialDecrease(xmpl_calc, 60, 9900);

CollateralOpts memory XMPL_A = CollateralOpts({
    ilk:                   "XMPL-A",
    gem:                   0xCE4F3774620764Ea881a8F8840Cbe0F701372283,
    join:                  0xa30925910067a2d9eB2a7358c017E6075F660842,
    clip:                  0x9daCc11dcD0aa13386D295eAeeBBd38130897E6f,
    calc:                  xmpl_calc,
    pip:                   0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a,
    isLiquidatable:        true,
    isOSM:                 true,
    whitelistOSM:          true,
    ilkDebtCeiling:        3 * MILLION,
    minVaultAmount:        100,         // 100 Dust
    maxLiquidationAmount:  50000,       // 50,000 Dai
    liquidationPenalty:    1300,        // 13% penalty
    ilkStabilityFee:       1000000000705562181084137268,
    startingPriceFactor:   13000,       // 1.3x multiplier
    auctionDuration:       6 hours,
    permittedDrop:         4000,        // 40% drop before reset
    liquidationRatio:      15000        // 150% collateralization ratio
});

DssExecLib.addNewCollateral(XMPL_A);

DssExecLib.setChangelogAddress("XMPL",          0xCE4F3774620764Ea881a8F8840Cbe0F701372283);
DssExecLib.setChangelogAddress("PIP_XMPL",      0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a);
DssExecLib.setChangelogAddress("MCD_JOIN_XMPL-A", 0xa30925910067a2d9eB2a7358c017E6075F660842);
DssExecLib.setChangelogAddress("MCD_CLIP_XMPL-A", 0x9daCc11dcD0aa13386D295eAeeBBd38130897E6f);
DssExecLib.setChangelogAddress("MCD_CLIP_CALC_XMPL-A", xmpl_calc);
```

- `ilk`:                  Collateral type
- `gem`:                  Address of collateral token
- `join`:                 Address of GemJoin contract
- `clip`:                 Address of Clip contract
- `calc`:                 Address of Abacus pricing contract
- `pip`:                  Address of Pip contract
- `isLiquidatable`:       Boolean indicating whether liquidations are enabled for collateral
- `isOsm`:                Boolean indicating whether pip address used is an OSM contract
- `whitelistOsm`:         Boolean indicating whether median is src in OSM.
- `ilkDebtCeiling`:       Debt ceiling for new collateral
- `minVaultAmount`:       Minimum DAI vault amount required for new collateral
- `maxLiquidationAmount`: Max DAI amount per vault for liquidation for new collateral
- `liquidationPenalty`:   Percent liquidation penalty for new collateral [ex. 13.5% == 1350]
- `ilkStabilityFee`:      Percent stability fee for new collateral       [ex. 4% == 1000000001243680656318820312]
- `startingPriceFactor`:  Percentage to multiply for initial auction price. [ex. 1.3x == 130% == 13000 bps]
- `auctionDuration`:      Total auction duration before reset for new collateral
- `permittedDrop`:        Percent an auction can drop before it can be reset.
- `liquidationRatio`:     Percent liquidation ratio for new collateral   [ex. 150% == 15000]

### Payments
- `sendPaymentFromSurplusBuffer(address _target, uint256 _amount)`: Send a payment in ERC20 DAI from the surplus buffer.

### Misc

- `function linearInterpolation(bytes32 _name, address _target, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration)`: Deploys a new general lerp contract with the associated parameters and returns the `address` of the contract.

- `function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration)`: Deploys a new lerp module specific to an ilk and returns the `address` of the contract.

## Testing

```
$ dapp update
$ make test
```

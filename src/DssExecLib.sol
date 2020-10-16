pragma solidity ^0.6.7;

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface DssVat {
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

// TODO: Is there a better way to set up these interfaces?
interface AuctionLike {
    function vat() external returns (address);
    function cat() external returns (address); // Only flip
    function beg() external returns (uint256);
    function pad() external returns (uint256); // Only flop
    function ttl() external returns (uint256);
    function tau() external returns (uint256);
    function ilk() external returns (bytes32); // Only flip
    function gem() external returns (bytes32); // Only flap/flop
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
}

// Includes Median and OSM functions
interface OracleLike {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

interface MomLike {
    function setOsm(bytes32, address) external;
}

interface RegistryLike {
    function add(address) external;
    function ilkData(bytes32) external returns (
        uint256       pos,   
        address       gem,   
        address       pip,   
        address       join,  
        address       flip,  
        uint256       dec,   
        string memory name,   
        string memory symbol
    );
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function getAddress(bytes32) external view returns (address);
}


contract DssExecLib {

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    /*******************************/
    /*** ChainLog Helper Functions */
    /*******************************/
    function vat()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_VAT"); }
    function cat()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_CAT"); }
    function jug()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_JUG"); }
    function pot()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_POT"); }
    function vow()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_VOW"); }
    function end()        public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_END"); }
    function reg()        public returns (address) { return ChainlogAbstract(LOG).getAddress("ILK_REG"); }
    function spot()       public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_SPOT"); }
    function flap()       public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_FLAP"); }
    function flop()       public returns (address) { return ChainlogAbstract(LOG).getAddress("MCD_FLOP"); }
    function osmMom()     public returns (address) { return ChainlogAbstract(LOG).getAddress("OSM_MOM"); }
    function govGuard()   public returns (address) { return ChainlogAbstract(LOG).getAddress("GOV_GUARD"); }
    function flipperMom() public returns (address) { return ChainlogAbstract(LOG).getAddress("FLIPPER_MOM"); }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    /**
        @dev Give an address authorization to perform auth actions on the contract.
        @param base   The address of the contract where the authorization will be set
        @param ward   Address to be authorized
    */
    function authorize(address base, address ward) public {
        Authorizable(base).rely(ward);
    }
    /**
        @dev Revoke contract authorization from an address.
        @param base   The address of the contract where the authorization will be revoked
        @param ward   Address to be deauthorized
    */
    function deauthorize(address base, address ward) public {
        Authorizable(base).deny(ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    /**
        @dev Update rate accumulation for the Dai Savings Rate (DSR).
    */
    function accumulateDSR() public {
        Drippable(pot()).drip();
    }
    /**
        @dev Update rate accumulation for the stability fees of a given collateral type.
        @param ilk   Collateral type
    */
    function accumulateCollateralStabilityFees(bytes32 ilk) public {
        Drippable(jug()).drip(ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    /**
        @dev Update price of a given collateral type.
        @param ilk   Collateral type
    */
    function updateCollateralPrice(bytes32 ilk) public {
        Pricing(spot()).poke(ilk);
    }
    /****************************/
    /*** System Configuration ***/
    /****************************/
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Cat contract in the Vat)
        @param base   The address of the contract where the new contract address will be filed
        @param what   Name of contract to file
        @param addr   Address of contract to file
    */
    function setContract(address base, bytes32 what, address addr) public {
        Fileable(base).file(what, addr);
    }
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Cat contract in the Vat)
        @param base   The address of the contract where the new contract address will be filed
        @param ilk    Collateral type
        @param what   Name of contract to file
        @param addr   Address of contract to file
    */
    function setContract(address base, bytes32 ilk, bytes32 what, address addr) public {
        Fileable(base).file(ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    /** 
        @dev Set the global debt ceiling. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setGlobalDebtCeiling(uint256 amount) public { setGlobalDebtCeiling(vat(), amount); }
    /**
        @dev Set the global debt ceiling. Amount will be converted to the correct internal precision.
        @param vat    The address of the Vat core accounting contract
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setGlobalDebtCeiling(address vat, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-global-Line-precision");
        Fileable(vat).file("Line", amount * RAD);
    }
    /**
        @dev Set the Dai Savings Rate.
        @param rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setDSR(uint256 rate) public {
        require((rate >= RAY) && (rate < 2 * RAY), "LibDssExec/dsr-out-of-bounds");
        Fileable(pot()).file("dsr", rate);
    }
    /** 
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(uint256 amount) public { setSurplusAuctionAmount(vow(), amount); }
    /** 
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param vow    The address of the Vow core contract
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(address vow, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-bump-precision");
        Fileable(vow).file("bump", amount * RAD);
    }
    /** 
        @dev Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusBuffer(uint256 amount) public { setSurplusBuffer(vow(), amount); }
    /** 
        @dev Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
        @param vow    The address of the Vow core contract
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusBuffer(address vow, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-hump-precision");
        Fileable(vow).file("hump", amount * RAD);
    }
    /**
        @dev Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setMinSurplusAuctionBidIncrease(uint256 pct) public {
        setMinSurplusAuctionBidIncrease(flap(), pct);
    }
    /**
        @dev Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * WAD / 100,000
        @param flap   The address of the Flapper core contract
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setMinSurplusAuctionBidIncrease(address flap, uint256 pct) public {
        require(pct < 100 * THOUSAND, "LibDssExec/incorrect-flap-beg-precision");
        Fileable(flap).file("beg", wdiv(pct, 100 * THOUSAND));
    }
    /**
        @dev Set bid duration for surplus auctions.
        @param length Amount of time for bids.
    */
    function setSurplusAuctionBidDuration(uint256 length) public {
        setSurplusAuctionBidDuration(flap(), length); 
    }
    /**
        @dev Set bid duration for surplus auctions.
        @param flap   The address of the Flapper core contract
        @param length Amount of time for bids.
    */
    function setSurplusAuctionBidDuration(address flap, uint256 length) public {
        Fileable(flap).file("ttl", length);
    }
    /**
        @dev Set total auction duration for surplus auctions.
        @param length Amount of time for auctions.
    */
    function setSurplusAuctionDuration(uint256 length) public {
        setSurplusAuctionDuration(flap(), length);
    }
    /**
        @dev Set total auction duration for surplus auctions.
        @param flap   The address of the Flapper core contract
        @param length Amount of time for auctions.
    */
    function setSurplusAuctionDuration(address flap, uint256 length) public {
        Fileable(flap).file("tau", length);
    }
    /** 
        @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
        @param length Duration in seconds
    */
    function setDebtAuctionDelay(uint256 length) public { setDebtAuctionDelay(vow(), length); }
    /** 
        @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
        @param vow    The address of the Vow core contract
        @param length Duration in seconds
    */
    function setDebtAuctionDelay(address vow, uint256 length) public {
        Fileable(vow).file("wait", length);
    }
    /** 
        @dev Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionDAIAmount(uint256 amount) public { setDebtAuctionDAIAmount(vow(), amount); }
    /** 
        @dev Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
        @param vow    The address of the Vow core contract
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionDAIAmount(address vow, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-sump-precision");
        Fileable(vow).file("sump", amount * RAD);
    }
    /** 
        @dev Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionMKRAmount(uint256 amount) public { setDebtAuctionMKRAmount(vow(), amount); }
    /** 
        @dev Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
        @param vow    The address of the Vow core contract
        @param amount The amount to set in MKR (ex. 250 MKR amount == 250)
    */
    function setDebtAuctionMKRAmount(address vow, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-dump-precision");
        Fileable(vow).file("dump", amount * WAD);
    }
    /**
        @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setMinDebtAuctionBidIncrease(uint256 pct) public {
        setMinDebtAuctionBidIncrease(flop(), pct);
    }
    /**
        @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * WAD / 100,000
        @param flop   The address of the Flopper core contract
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setMinDebtAuctionBidIncrease(address flop, uint256 pct) public {
        require(pct < 100 * THOUSAND, "LibDssExec/incorrect-flap-beg-precision");
        Fileable(flop).file("beg", wdiv(pct, 100 * THOUSAND));
    }
    /**
        @dev Set bid duration for debt auctions.
        @param length Amount of time for bids.
    */
    function setDebtAuctionBidDuration(uint256 length) public {
        setDebtAuctionBidDuration(flop(), length); 
    }
    /**
        @dev Set bid duration for debt auctions.
        @param flop   The address of the Flopper core contract
        @param length Amount of time for bids.
    */
    function setDebtAuctionBidDuration(address flop, uint256 length) public {
        Fileable(flop).file("ttl", length);
    }
    /**
        @dev Set total auction duration for debt auctions.
        @param length Amount of time for auctions.
    */
    function setDebtAuctionDuration(uint256 length) public {
        setDebtAuctionDuration(flop(), length);
    }
    /**
        @dev Set total auction duration for debt auctions.
        @param flop   The address of the Flopper core contract
        @param length Amount of time for auctions.
    */
    function setDebtAuctionDuration(address flop, uint256 length) public {
        Fileable(flop).file("tau", length);
    }
    /** 
        @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
        @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setDebtAuctionMKRIncreaseRate(uint256 pct) public { setDebtAuctionMKRIncreaseRate(vow(), pct); }
    /** 
        @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
        @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
        @dev Equation used for conversion is (pct + 100,000) * WAD / 100,000 (ex. changes 50% to 150% WAD needed for pad)
        @param flop   The address of the Flopper core contract
        @param pct    The pct to set in integer form (x1000). (ex. 50% = 50 * 1000 = 50000)
    */
    function setDebtAuctionMKRIncreaseRate(address flop, uint256 pct) public {
        Fileable(flop).file("pad", wdiv(add(pct, 100 * THOUSAND), 100 * THOUSAND));
    }
    /** 
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setMaxTotalDAILiquidationAmount(uint256 amount) public { setMaxTotalDAILiquidationAmount(cat(), amount); }
    /** 
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param cat    The address of the Cat core contract
        @param amount The amount to set in DAI (ex. 250,000 DAI amount == 250000)
    */
    function setMaxTotalDAILiquidationAmount(address cat, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-dump-precision");
        Fileable(cat).file("box", amount * WAD);
    }
    /** 
        @dev Set the length of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param length Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(uint256 length) public { setEmergencyShutdownProcessingTime(cat(), length); }
    /** 
        @dev Set the length of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param end    The address of the End core contract
        @param length Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(address end, uint256 length) public {
        Fileable(end).file("wait", length);
    }
        /**
        @dev Set the global stability fee (is not typically used, currently is 0).
        @param rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(uint256 rate) public { setGlobalStabilityFee(jug(), rate); }
    /**
        @dev Set the global stability fee (is not typically used, currently is 0).
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):
            
            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
            
            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

        @param jug    The address of the Jug core accounting contract
        @param rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(address jug, uint256 rate) public {
        require((rate >= RAY) && (rate < 2 * RAY), "LibDssExec/global-stability-fee-out-of-bounds");
        Fileable(jug).file("base", rate);
    }
    /**
        @dev Set the value of DAI in the reference asset (e.g. $1 per DAI). Amount will be converted to the correct internal precision.
        @param amount The amount to set as integer (x1000) (ex. $1.025 == 1025)
    */
    function setDAIReferenceValue(uint256 amount) public { setDAIReferenceValue(spot(), amount); }
    /**
        @dev Set the value of DAI in the reference asset (e.g. $1 per DAI). Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is amount * RAY / 1000
        @param spot   The address of the Spot core contract 
        @param amount The amount to set as integer (x1000) (ex. $1.025 == 1025)
    */
    function setDAIReferenceValue(address spot, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-ilk-dunk-precision");
        Fileable(spot).file("par", rdiv(amount, 1000));
    }
    
    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    /**
        @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) public { setIlkDebtCeiling(vat(), ilk, amount); }
    /**
        @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param vat    The address of the Vat core accounting contract
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkDebtCeiling(address vat, bytes32 ilk, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-ilk-line-precision");
        Fileable(vat).file(ilk, "line", amount * RAD);
    }
    /**
        @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) public { setIlkMinVaultAmount(vat(), ilk, amount); }
    /**
        @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
        @param vat    The address of the Vat core accounting contract
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMinVaultAmount(address vat, bytes32 ilk, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-ilk-dust-precision");
        Fileable(vat).file(ilk, "dust", amount * RAD);
    }
    /**
        @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param pct    The pct to set in integer form (x1000). (ex. 10.25% = 10.25 * 1000 = 10250)
    */
    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct) public { setIlkLiquidationPenalty(cat(), ilk, pct); }
    /**
        @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (pct + 100,000) * WAD / 100,000 (ex. changes 13% to 113% WAD needed for chop)
        @param cat    The address of the Cat core accounting contract (will need to revisit for LIQ-2.0)
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param pct    The pct to set in integer form (x1000). (ex. 10.25% = 10.25 * 1000 = 10250)
    */
    function setIlkLiquidationPenalty(address cat, bytes32 ilk, uint256 pct) public {
        require(pct < 100 * THOUSAND, "LibDssExec/incorrect-ilk-chop-precision");
        Fileable(cat).file(ilk, "chop", wdiv(add(pct, 100 * THOUSAND), 100 * THOUSAND));
    }
    /**
        @dev Set max DAI amount for liquidation per vault for a collateral type. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) public { setIlkMaxLiquidationAmount(cat(), ilk, amount); }
    /**
        @dev Set max DAI amount for liquidation per vault for collateral. Amount will be converted to the correct internal precision.
        @param cat    The address of the Cat core accounting contract (will need to revisit for LIQ-2.0)
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMaxLiquidationAmount(address cat, bytes32 ilk, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-ilk-dunk-precision");
        Fileable(cat).file(ilk, "dunk", amount * RAD);
    }
    /**
        @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param pct    The pct to set in integer form (x1000). (ex. 150% = 150 * 1000 = 150000)
    */
    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct) public { setIlkLiquidationRatio(spot(), ilk, pct); }
    /**
        @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * RAY / 100,000
        @param spot   The address of the Spot core accounting contract
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param pct    The pct to set in integer form (x1000). (ex. 150% = 150 * 1000 = 150000)
    */
    function setIlkLiquidationRatio(address spot, bytes32 ilk, uint256 pct) public {
        require(pct < 1 * MILLION, "LibDssExec/incorrect-ilk-mat-precision"); // Fails if pct >= 1000%
        Fileable(spot).file(ilk, "mat", rdiv(pct, 100 * THOUSAND));
    }
    /**
        @dev Set minimum bid increase for collateral. Amount will be converted to the correct internal precision.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct) public {
        (,,,, address flip,,,) = RegistryLike(reg()).ilkData(ilk);
        setIlkMinAuctionBidIncrease(flip, pct);
    }
    /**
        @dev Set minimum bid increase for collateral. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * WAD / 100,000
        @param flip   The address of the ilk's flip core accounting contract
        @param pct    The pct to set in integer form (x1000). (ex. 5% = 5 * 1000 = 5000)
    */
    function setIlkMinAuctionBidIncrease(address flip, uint256 pct) public {
        require(pct < 100 * THOUSAND, "LibDssExec/incorrect-ilk-chop-precision");
        Fileable(flip).file("beg", wdiv(pct, 100 * THOUSAND));
    }
    /**
        @dev Set bid duration for a collateral type.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param length Amount of time for bids.
    */
    function setIlkBidDuration(bytes32 ilk, uint256 length) public {
        (,,,, address flip,,,) = RegistryLike(reg()).ilkData(ilk);
        setIlkBidDuration(flip, length); 
    }
    /**
        @dev Set bid duration for a collateral type.
        @param flip   The address of the ilk's flip core accounting contract
        @param length Amount of time for bids.
    */
    function setIlkBidDuration(address flip, uint256 length) public {
        Fileable(flip).file("ttl", length);
    }
    /**
        @dev Set auction duration for a collateral type.
        @param ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param length Amount of time for auctions.
    */
    function setIlkAuctionDuration(bytes32 ilk, uint256 length) public {
        (,,,, address flip,,,) = RegistryLike(reg()).ilkData(ilk);
        setIlkAuctionDuration(flip, length);
    }
    /**
        @dev Set auction duration for a collateral type.
        @param flip   The address of the ilk's flip core accounting contract
        @param length Amount of time for auctions.
    */
    function setIlkAuctionDuration(address flip, uint256 length) public {
        Fileable(flip).file("tau", length);
    }
    /**
        @dev Set the stability fee for a given ilk.
        @param ilk     The ilk to update (ex. bytes32("ETH-A"))
        @param rate    The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setIlkStabilityFee(bytes32 ilk, uint256 rate) public { setIlkStabilityFee(jug(), ilk, rate, true); }
    /**
        @dev Set the stability fee for a given ilk.
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):
            
            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
            
            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

        @param jug    The address of the Jug core accounting contract
        @param ilk    The ilk to update (ex. bytes32("ETH-A") )
        @param rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param doDrip `true` to accumulate stability fees for the collateral
    */
    function setIlkStabilityFee(address jug, bytes32 ilk, uint256 rate, bool doDrip) public {
        require((rate >= RAY) && (rate < 2 * RAY), "LibDssExec/ilk-stability-fee-out-of-bounds");
        if (doDrip) Drippable(jug).drip(ilk);

        Fileable(jug).file(ilk, "duty", rate);
    }


    /***********************/
    /*** Core Management ***/
    /***********************/
    /**
        @dev Update collateral auction contracts.
        @param ilk     The collateral's auction contract to update
        @param newFlip New auction contract address
        @param oldFlip Old auction contract address
    */
    function updateCollateralAuctionContract(bytes32 ilk, address newFlip, address oldFlip) public {
        updateCollateralAuctionContract(vat(), cat(), end(), flipperMom(), ilk, newFlip, oldFlip);
    }
    /**
        @dev Update collateral auction contracts.
        @param vat        Vat core contract address
        @param cat        Cat core contract address
        @param end        End core contract address
        @param flipperMom Flipper Mom core contract address
        @param ilk        The collateral's auction contract to update
        @param newFlip    New auction contract address
        @param oldFlip    Old auction contract address
    */
    function updateCollateralAuctionContract(
        address vat,
        address cat, 
        address end,
        address flipperMom,
        bytes32 ilk, 
        address newFlip, 
        address oldFlip
    ) public {
        // Add new flip address to Cat
        setContract(cat, ilk, "flip", newFlip);

        // Authorize MCD contracts from new flip
        authorize(newFlip, cat);
        authorize(newFlip, end);
        authorize(newFlip, flipperMom);

        // Authorize MCD contracts from old flip
        deauthorize(oldFlip, cat);
        deauthorize(oldFlip, end);
        deauthorize(oldFlip, flipperMom);

        // Transfer auction params from old flip to new flip
        Fileable(newFlip).file("beg", AuctionLike(oldFlip).beg());
        Fileable(newFlip).file("ttl", AuctionLike(oldFlip).ttl());
        Fileable(newFlip).file("tau", AuctionLike(oldFlip).tau());

        // Sanity checks
        require(AuctionLike(newFlip).ilk() == ilk, "non-matching-ilk");
        require(AuctionLike(newFlip).vat() == vat, "non-matching-vat");
    }
    /**
        @dev Update surplus auction contracts.
        @param ilk     The surplus's auction contract to update
        @param newFlap New surplus auction contract address
        @param oldFlap Old surplus auction contract address
    */
    function updateSurplusAuctionContract(bytes32 ilk, address newFlap, address oldFlap) public {
        updateSurplusAuctionContract(vat(), vow(), newFlap, oldFlap);
    }
    /**
        @dev Update surplus auction contracts.
        @param vat     Vat core contract address
        @param vow     Vow core contract address
        @param newFlap New surplus auction contract address
        @param oldFlap Old surplus auction contract address
    */
    function updateSurplusAuctionContract(address vat, address vow, address newFlap, address oldFlap) public {
        // Add new flap address to Vow
        setContract(vow, "flapper", newFlap);

        // Authorize MCD contracts from new flap
        authorize(newFlap, vow);

        // Authorize MCD contracts from old flap
        deauthorize(oldFlap, vow);

        // Transfer auction params from old flap to new flap
        Fileable(newFlap).file("beg", AuctionLike(oldFlap).beg());
        Fileable(newFlap).file("ttl", AuctionLike(oldFlap).ttl());
        Fileable(newFlap).file("tau", AuctionLike(oldFlap).tau());

        // Sanity checks
        require(AuctionLike(newFlap).gem() == AuctionLike(oldFlap).gem(), "non-matching-gem");
        require(AuctionLike(newFlap).vat() == vat,                        "non-matching-vat");
    }
    /**
        @dev Update debt auction contracts.
        @param newFlop New debt auction contract address
        @param oldFlop Old debt auction contract address
    */
    function updateDebtAuctionContract(bytes32 ilk, address newFlop, address oldFlop) public {
        updateDebtAuctionContract(vat(), vow(), govGuard(), newFlop, oldFlop);
    }
    /**
        @dev Update debt auction contracts.
        @param vat          Vat core contract address
        @param vow          Vow core contract address
        @param mkrAuthority MKRAuthority core contract address
        @param newFlop      New debt auction contract address
        @param oldFlop      Old debt auction contract address
    */
    function updateDebtAuctionContract(address vat, address vow, address mkrAuthority, address newFlop, address oldFlop) public {
        // Add new flop address to Vow
        setContract(vow, "flopper", newFlop);

        // Authorize MCD contracts for new flop
        authorize(newFlop, vow);
        authorize(vat, newFlop);
        authorize(mkrAuthority, newFlop);

        // Deauthorize MCD contracts for old flop
        deauthorize(oldFlop, vow);
        deauthorize(vat, oldFlop);
        deauthorize(mkrAuthority, oldFlop);

        // Transfer auction params from old flop to new flop
        Fileable(newFlop).file("beg", AuctionLike(oldFlop).beg());
        Fileable(newFlop).file("pad", AuctionLike(oldFlop).pad());
        Fileable(newFlop).file("ttl", AuctionLike(oldFlop).ttl());
        Fileable(newFlop).file("tau", AuctionLike(oldFlop).tau());

        // Sanity checks
        require(AuctionLike(newFlop).gem() == AuctionLike(oldFlop).gem(), "non-matching-gem");
        require(AuctionLike(newFlop).vat() == vat,                        "non-matching-vat");
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    /**
        @dev Adds oracle feeds to the Median's writer whitelist, allowing the feeds to write prices.
        @param median Median core contract address
        @param feeds      Array of oracle feed addresses to add to whitelist
    */
    function addWritersToMedianWhitelist(address median, address[] memory feeds) public {
        OracleLike(median).lift(feeds);
    }
    /**
        @dev Removes oracle feeds to the Median's writer whitelist, disallowing the feeds to write prices.
        @param median Median core contract address
        @param feeds      Array of oracle feed addresses to remove from whitelist
    */
    function removeWritersFromMedianWhitelist(address median, address[] memory feeds) public {
        OracleLike(median).drop(feeds);
    }
    /**
        @dev Adds addresses to the Median's reader whitelist, allowing the addresses to read prices from the median.
        @param median Median core contract address
        @param readers    Array of addresses to add to whitelist
    */
    function addReadersToMedianWhitelist(address median, address[] memory readers) public {
        OracleLike(median).kiss(readers);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the median.
        @param median Median core contract address
        @param reader     Address to add to whitelist
    */
    function addReaderToMedianWhitelist(address median, address reader) public {
        OracleLike(median).kiss(reader);
    }
    /**
        @dev Removes addresses from the Median's reader whitelist, disallowing the addresses to read prices from the median.
        @param median Median core contract address
        @param readers    Array of addresses to remove from whitelist
    */
    function removeReadersFromMedianWhitelist(address median, address[] memory readers) public {
        OracleLike(median).diss(readers);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the median.
        @param median Median core contract address
        @param reader     Address to remove from whitelist
    */
    function removeReaderFromMedianWhitelist(address median, address reader) public {
        OracleLike(median).diss(reader);
    }
    /**
        @dev Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
        @param median Median core contract address
        @param minQuorum  Minimum number of valid messages from whitelisted oracle feeds needed to update median price (NOTE: MUST BE ODD NUMBER)
    */
    function setMedianWritersQuorum(address median, uint256 minQuorum) public {
        OracleLike(median).setBar(minQuorum);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the OSM.
        @param osm        Oracle Security Module (OSM) core contract address
        @param reader     Address to add to whitelist
    */
    function addReaderToOSMWhitelist(address osm, address reader) public {
        OracleLike(osm).kiss(reader);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the OSM.
        @param osm        Oracle Security Module (OSM) core contract address
        @param reader     Address to remove from whitelist
    */
    function removeReaderFromOSMWhitelist(address osm, address reader) public {
        OracleLike(osm).diss(reader);
    }
    /**
        @dev Add OSM address to OSM mom, allowing it to be frozen by governance.
        @param osm        Oracle Security Module (OSM) core contract address
        @param ilk        Collateral type using OSM
    */
    function allowOSMFreeze(address osm, bytes32 ilk) public {
        allowOSMFreeze(osmMom(), osm, ilk);
    }
    /**
        @dev Add OSM address to OSM mom, allowing it to be frozen by governance.
        @param osmMom     OSM Mom core contract address
        @param osm        Oracle Security Module (OSM) core contract address
        @param ilk        Collateral type using OSM
    */
    function allowOSMFreeze(address osmMom, address osm, bytes32 ilk) public {
        MomLike(osmMom).setOsm(ilk, osm);
    }


    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/
    /**
        @dev Adds new collateral to MCD following standard collateral onboarding procedure.
        @param ilk                  Collateral type
        @param addresses            Array of contract addresses: [tokenAddress, join, flip, pip]
        @param liquidatable         Boolean indicating whether liquidations are enabled for collateral
        @param isOsm                Boolean indicating whether pip address used is an OSM contract
        @param ilkDebtCeiling       Debt ceiling for new collateral
        @param minVaultAmount       Minimum DAI vault amount required for new collateral
        @param maxLiquidationAmount Max DAI amount per vault for liquidation for new collateral
        @param liquidationPenalty   Percent liquidation penalty for new collateral [ex. 13.5% == 13500]
        @param ilkStabilityFee      Percent stability fee for new collateral       [ex. 4% == 1000000001243680656318820312]
        @param bidIncrease          Percent bid increase for new collateral        [ex. 13.5% == 13500]
        @param bidDuration          Bid period duration for new collateral  
        @param auctionDuration      Total auction duration for new collateral
        @param liquidationRatio     Percent liquidation ratio for new collateral   [ex. 150% == 150000] 
    */
    function addNewCollateral(
        bytes32 ilk,
        address[] memory addresses,
        bool    liquidatable,
        bool    isOsm,
        uint256 ilkDebtCeiling,
        uint256 minVaultAmount,
        uint256 maxLiquidationAmount,
        uint256 liquidationPenalty,
        uint256 ilkStabilityFee,
        uint256 bidIncrease,
        uint256 bidDuration,
        uint256 auctionDuration,
        uint256 liquidationRatio
    ) public {
        // Sanity checks
        require(JoinLike(addresses[1]).vat() == vat(),       "join-vat-not-match");
        require(JoinLike(addresses[1]).ilk() == ilk,           "join-ilk-not-match");
        require(JoinLike(addresses[1]).gem() == addresses[0],  "join-gem-not-match");
        require(JoinLike(addresses[1]).dec() == 18,            "join-dec-not-match");
        require(AuctionLike(addresses[2]).vat() == vat(),    "flip-vat-not-match");
		require(AuctionLike(addresses[2]).cat() == cat(),    "flip-cat-not-match");
        require(AuctionLike(addresses[2]).ilk() == ilk,        "flip-ilk-not-match");

        // Set the token PIP in the Spotter
        setContract(spot(), ilk, "pip", addresses[3]);

        // Set the ilk Flipper in the Cat
        setContract(cat(), ilk, "flip", addresses[2]);

        // Init ilk in Vat & Jug
        Initializable(vat()).init(ilk);
        Initializable(jug()).init(ilk);

        // Allow ilk Join to modify Vat registry
        authorize(vat(), addresses[1]);
		// Allow the ilk Flipper to reduce the Cat litterbox on deal()
        authorize(cat(), addresses[2]);
        // Allow Cat to kick auctions in ilk Flipper
        authorize(addresses[2], cat());
        // Allow End to yank auctions in ilk Flipper
        authorize(addresses[2], end());
        // Allow FlipperMom to access to the ilk Flipper
        authorize(addresses[2], flipperMom());
        // Disallow Cat to kick auctions in ilk Flipper
        if(!liquidatable) deauthorize(flipperMom(), addresses[2]);

        if(isOsm) {
            // Allow OsmMom to access to the TOKEN Osm
            authorize(addresses[3], osmMom());
            // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToMedianWhitelist(address(OracleLike(addresses[3]).src()), addresses[3]);
            // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(addresses[3], spot());
            // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(addresses[3], end());
            // Set TOKEN Osm in the OsmMom for new ilk
            allowOSMFreeze(addresses[3], ilk);
        }

        // Set the ilk debt ceiling
        setIlkDebtCeiling(ilk, ilkDebtCeiling);
        // Set the ilk dust
        setIlkMinVaultAmount(ilk, minVaultAmount);
        // Set the Lot size
        setIlkMaxLiquidationAmount(ilk, maxLiquidationAmount);
        // Set the ilk liquidation penalty
        setIlkLiquidationPenalty(cat(), ilk, liquidationPenalty);
        // Set the ilk stability fee
        setIlkStabilityFee(ilk, ilkStabilityFee);
        // Set the ilk percentage between bids
        setIlkMinAuctionBidIncrease(ilk, bidIncrease);
        // Set the ilk time max time between bids
        setIlkBidDuration(ilk, bidDuration);
        // Set the ilk max auction duration to
        setIlkAuctionDuration(ilk, auctionDuration);
        // Set the ilk min collateralization ratio 
        setIlkLiquidationRatio(ilk, liquidationRatio);

        // Update ilk spot value in Vat
        updateCollateralPrice(ilk);

        // Add new ilk to the IlkRegistry
        RegistryLike(reg()).add(addresses[1]);
    }
}

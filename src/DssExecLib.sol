pragma solidity ^0.6.7;

interface Initialization {
    function init(bytes32) external;
}

interface Authorization {
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

interface RegistryLike {
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

library DssExecLib {

    address constant public MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_CAT     = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_JUG     = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT     = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_VOW     = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public MCD_SPOT    = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_FLAP    = 0xC4269cC7acDEdC3794b221aA4D9205F564e27f0d;
    address constant public MCD_FLOP    = 0xA41B6EF151E06da0e34B009B86E828308986736D;
    address constant public MCD_END     = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public ILK_REG     = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

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

    /**********************/
    /*** Authorizations ***/
    /**********************/

    /**
        @dev Give an address authorization to perform auth actions on the contract.
        @param base   The address of the contract where the authorization will be set
        @param ward   Address to be authorized
    */
    function authorize(address base, address ward) public {
        Authorization(base).rely(ward);
    }
    /**
        @dev Revoke contract authorization from an address.
        @param base   The address of the contract where the authorization will be revoked
        @param ward   Address to be deauthorized
    */
    function deauthorize(address base, address ward) public {
        Authorization(base).deny(ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/

    /**
        @dev Update rate accumulation for the Dai Savings Rate (DSR).
    */
    function accumulateDSR() public {
        Drippable(MCD_POT).drip();
    }
    /**
        @dev Update rate accumulation for the stability fees of a given collateral type.
        @param ilk   Collateral type
    */
    function accumulateCollateralStabilityFees(bytes32 ilk) public {
        Drippable(MCD_JUG).drip(ilk);
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
    function setGlobalDebtCeiling(uint256 amount) public { setGlobalDebtCeiling(MCD_VAT, amount); }
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
        Fileable(MCD_POT).file("dsr", rate);
    }
    /** 
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(uint256 amount) public { setSurplusAuctionAmount(MCD_VOW, amount); }
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
    function setSurplusBuffer(uint256 amount) public { setSurplusBuffer(MCD_VOW, amount); }
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
        setMinSurplusAuctionBidIncrease(MCD_FLAP, pct);
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
        setSurplusAuctionBidDuration(MCD_FLAP, length); 
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
    function setSurplusAuctionDuration(bytes32 ilk, uint256 length) public {
        setSurplusAuctionDuration(MCD_FLAP, length);
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
    function setDebtAuctionDelay(uint256 length) public { setDebtAuctionDelay(MCD_VOW, length); }
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
    function setDebtAuctionDAIAmount(uint256 amount) public { setDebtAuctionDAIAmount(MCD_VOW, amount); }
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
    function setDebtAuctionMKRAmount(uint256 amount) public { setDebtAuctionMKRAmount(MCD_VOW, amount); }
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
        setMinDebtAuctionBidIncrease(MCD_FLOP, pct);
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
        setDebtAuctionBidDuration(MCD_FLOP, length); 
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
    function setDebtAuctionDuration(bytes32 ilk, uint256 length) public {
        setDebtAuctionDuration(MCD_FLOP, length);
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
    function setDebtAuctionMKRIncreaseRate(uint256 pct) public { setDebtAuctionMKRIncreaseRate(MCD_VOW, pct); }
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
    function setMaxTotalDAILiquidationAmount(uint256 amount) public { setMaxTotalDAILiquidationAmount(MCD_CAT, amount); }
    /** 
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param cat    The address of the Cat core contract
        @param amount The amount to set in MKR (ex. 250 MKR amount == 250)
    */
    function setMaxTotalDAILiquidationAmount(address cat, uint256 amount) public {
        require(amount < WAD, "LibDssExec/incorrect-vow-dump-precision");
        Fileable(cat).file("box", amount * WAD);
    }
    /** 
        @dev Set the length of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param length Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(uint256 length) public { setEmergencyShutdownProcessingTime(MCD_CAT, length); }
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
        @param rate    The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(uint256 rate) public { setGlobalStabilityFee(MCD_JUG, rate); }
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
    function setDAIReferenceValue(uint256 amount) public { setDAIReferenceValue(MCD_SPOT, amount); }
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
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) public { setIlkDebtCeiling(MCD_VAT, ilk, amount); }
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
    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) public { setIlkMinVaultAmount(MCD_VAT, ilk, amount); }
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
    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct) public { setIlkLiquidationPenalty(MCD_CAT, ilk, pct); }
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
    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) public { setIlkMaxLiquidationAmount(MCD_CAT, ilk, amount); }
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
    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct) public { setIlkLiquidationRatio(MCD_SPOT, ilk, pct); }
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
        (,,,, address flip,,,) = RegistryLike(ILK_REG).ilkData(ilk);
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
        (,,,, address flip,,,) = RegistryLike(ILK_REG).ilkData(ilk);
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
        (,,,, address flip,,,) = RegistryLike(ILK_REG).ilkData(ilk);
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
    function setIlkStabilityFee(bytes32 ilk, uint256 rate) public { setIlkStabilityFee(MCD_JUG, ilk, rate, true); }
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

    
    ///////////////////////////////
    //// Collateral Onboarding ////
    ///////////////////////////////

    // TODO addCollateral
    // FIXME in progress
    function addNewCollateral(
        bytes32 ilk,
        address join,
        address pip,
        address flip,
        bool    liquidations
        ) public {
        Initialization(MCD_VAT).init(ilk);
        Initialization(MCD_JUG).init(ilk);

        authorize(MCD_VAT, join);

        Fileable(MCD_SPOT).file(ilk, "pip", pip);
        Fileable(MCD_CAT).file(ilk, "flip", flip);

        authorize(flip, MCD_CAT);
        authorize(flip, MCD_END);
        authorize(flip, FLIPPER_MOM);

        // set line
        // set dust
        // set lump
        // set chop
        // set duty
        // set beg
        // set ttl
        // set tau
        // set mat

        Pricing(MCD_SPOT).poke(ilk);

        if (!liquidations) {
            deauthorize(FLIPPER_MOM, flip);
        }
    }

    /////////////////////////
    //// Core Management ////
    /////////////////////////

    // TODO change flip (oldFlip, newFlip)
    // TODO set surplus buffer (hump [RAD])


    ///////////////////////////
    //// Oracle Management ////
    ///////////////////////////

    // TODO

    // median lift
    // median drop

    // median kiss

    // osm kiss
}

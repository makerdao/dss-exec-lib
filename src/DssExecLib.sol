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

contract DssExecLib {

    address constant public MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_CAT     = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_JUG     = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT     = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_SPOT    = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_END     = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    ////////////////////////
    //// Authorizations ////
    ////////////////////////

    function setRely(address base, address ward) public {
        Authorization(base).rely(ward);
    }

    function setDeny(address base, address ward) public {
        Authorization(base).deny(ward);
    }

    ///////////////////////
    ////  Dripping MCD ////
    ///////////////////////

    function drip() public {
        Drippable(MCD_POT).drip();
    }

    function drip(bytes32 ilk) public {
        Drippable(MCD_JUG).drip(ilk);
    }

    ///////////////////////
    //// Debt Ceilings ////
    ///////////////////////

    // Set the global debt ceiling
    //
    // @param amount  The amount to increase or decrease the global Line value
    function setGlobalLine(uint256 amount) public {
        setGlobalLine(MCD_VAT, amount);
    }

    // Set the global debt ceiling
    //
    // @param vat     The address of the Vat core accounting contract
    // @param amount  The amount to increase or decrease the global Line value
    //   Example: 10 million Dai amount will be 10000000
    //   Amount will be converted to the correct internal precision
    function setGlobalLine(address vat, uint256 amount) public {
        // Precision checks
        require(amount < WAD, "LibDssExec/incorrect-global-Line-precision");

        Fileable(vat).file("Line", amount * RAD);
    }

    // Set a collateral debt ceiling
    //
    // @param ilk     The ilk to update (ex. bytes32("ETH-A") )
    // @param amount  The amount to set in Dai. (ex. 10m Dai amount == 10000000)
    function setIlkLine(bytes32 ilk, uint256 amount) public {
        setIlkLine(MCD_VAT, ilk, amount);
    }

    // Set a collateral debt ceiling
    //
    // @param vat     The address of the Vat core accounting contract
    // @param ilk     The ilk to update (ex. bytes32("ETH-A") )
    // @param amount  The amount to set in Dai. (ex. 10m Dai amount == 10000000)
    function setIlkLine(address vat, bytes32 ilk, uint256 amount) public {
        // Precision checks
        require(amount < WAD, "LibDssExec/incorrect-ilk-line-precision");

        Fileable(vat).file(ilk, "line", amount * RAD);
    }

    // TODO increaseIlkLine

    // TODO decreaseIlkLine

    ////////////////////////
    //// Stability Fees ////
    ////////////////////////

    // Set the stability fee for a given ilk.
    //
    // @param ilk     The ilk to update (ex. bytes32("ETH-A") )
    // @param rate    The accumulated rate (ex. 4% => 1000000001243680656318820312)
    function setStabilityFee(bytes32 ilk, uint256 rate) public {
        setStabilityFee(MCD_JUG, ilk, rate, true);
    }

    // Set the stability fee for a given ilk.
    //
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can also be found at:
    //   https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    //
    // @param jug     The address of the Jug core accounting contract
    // @param ilk     The ilk to update (ex. bytes32("ETH-A") )
    // @param rate    The accumulated rate (ex. 4% => 1000000001243680656318820312)
    // @param drip    `true` to accumulate stability fees for the collateral
    function setStabilityFee(address jug, bytes32 ilk, uint256 rate, bool doDrip) public {
        // precision check
        require((rate >= RAY) && (rate < 2 * RAY), "LibDssExec/stability-fee-out-of-bounds");

        if (doDrip) {
             Drippable(jug).drip(ilk);
        }

        Fileable(jug).file(ilk, "duty", rate);
    }

    //////////////////////////
    //// Dai Savings Rate ////
    //////////////////////////

    // Set the Dai Savings Rate
    //
    // @param rate The accumulated rate (ex. 4% => 1000000001243680656318820312)
    //    See setStabilityFee()
    function setDSR(uint256 rate) public {
        require((rate >= RAY) && (rate < 2 * RAY), "LibDssExec/dsr-out-of-bounds");

        Fileable(MCD_POT).file("dsr", rate);
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

        setRely(MCD_VAT, join);

        Fileable(MCD_SPOT).file(ilk, "pip", pip);
        Fileable(MCD_CAT).file(ilk, "flip", flip);

        setRely(flip, MCD_CAT);
        setRely(flip, MCD_END);
        setRely(flip, FLIPPER_MOM);

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
            setDeny(FLIPPER_MOM, flip);
        }
    }

    /////////////////////////
    //// Core Management ////
    /////////////////////////

    // TODO change flip (oldFlip, newFlip)
    // TODO set surplus buffer (hump [RAD])

    ///////////////////////////////
    //// Collateral Management ////
    ///////////////////////////////

    // TODO set vault dust (ilk, dust [RAD])

    // TODO set minimum vault (ilk, hump [RAD])
    // TODO set auction size (ilk, lump [WAD])

    // TODO spot liquidation ratio (ilk, mat [RAY])

    // TODO poke(spot, ilk)

    // TODO cage


    ///////////////////////////
    //// Oracle Management ////
    ///////////////////////////

    // TODO

    // median lift
    // median drop

    // median kiss

    // osm kiss
}

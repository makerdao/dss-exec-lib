pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {ChainLog} from "dss-chain-log/ChainLog.sol";
import "osm-mom/OsmMom.sol";
import "mkr-authority/MkrAuthority.sol";
import {IlkRegistry} from "ilk-registry/IlkRegistry.sol";
import "flipper-mom/FlipperMom.sol";
import {Median} from "median/median.sol";
import {OsmAbstract} from "dss-interfaces/Interfaces.sol";

import {Vat}  from 'dss/vat.sol';
import {Cat}  from 'dss/cat.sol';
import {Vow}  from 'dss/vow.sol';
import {Pot}  from 'dss/pot.sol';
import {Jug}  from 'dss/jug.sol';
import {Flipper} from 'dss/flip.sol';
import {Flapper} from 'dss/flap.sol';
import {Flopper} from 'dss/flop.sol';
import {GemJoin} from 'dss/join.sol';
import {End}  from 'dss/end.sol';
import {Spotter} from 'dss/spot.sol';

import {DssAction} from './DssAction.sol';
import {DssExecLib} from './DssExecLib.sol';

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract EndTest is DSTest {
    Hevm hevm;

    Vat   vat;
    End   end;
    Vow   vow;
    Pot   pot;
    Jug   jug;
    Cat   cat;

    IlkRegistry  reg;
    Median median;
    OsmMom       osmMom;
    MkrAuthority govGuard;
    FlipperMom flipperMom;

    ChainLog log;

    Spotter spot;
    Flapper flap;
    Flopper flop;

    DssAction action;
    DssExecLib lib;

    struct Ilk {
        DSValue pip;
        DSToken gem;
        GemJoin gemA;
        Flipper flip;
    }

    mapping (bytes32 => Ilk) ilks;

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant MLN = 10 ** 6;

    uint256 constant START_TIME = 604411200;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        (x >= y) ? z = y : z = x;
    }
    function dai(address urn) internal view returns (uint) {
        return vat.dai(urn) / RAY;
    }
    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, urn);
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); art_;
        return ink_;
    }
    function art(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); ink_;
        return art_;
    }
    function Art(bytes32 ilk) internal view returns (uint) {
        (uint Art_, uint rate_, uint spot_, uint line_, uint dust_) = vat.ilks(ilk);
        rate_; spot_; line_; dust_;
        return Art_;
    }
    function balanceOf(bytes32 ilk, address usr) internal view returns (uint) {
        return ilks[ilk].gem.balanceOf(usr);
    }

    function init_collateral(bytes32 name) internal returns (Ilk memory) {
        DSToken coin = new DSToken(name);
        coin.mint(20 ether);

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(1.5 ether));
        // initial collateral price of 5
        pip.poke(bytes32(5 * WAD));

        vat.init(name);
        GemJoin gemA = new GemJoin(address(vat), name, address(coin));

        // 1 coin = 6 dai and liquidation ratio is 200%
        vat.file(name, "spot",    ray(3 ether));
        vat.file(name, "line", rad(1000 ether));

        coin.approve(address(gemA));
        coin.approve(address(vat));

        vat.rely(address(gemA));

        Flipper flip = new Flipper(address(vat), address(cat), name);
        vat.hope(address(flip));
        flip.rely(address(end));
        flip.rely(address(cat));
        cat.rely(address(flip));
        cat.file(name, "flip", address(flip));
        cat.file(name, "chop", 1 ether);
        cat.file(name, "dunk", rad(25000 ether));
        cat.file("box", rad((10 ether) * MLN));

        ilks[name].pip = pip;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].flip = flip;

        return ilks[name];
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(START_TIME);

        vat = new Vat();
        DSToken gov = new DSToken('GOV');

        flap = new Flapper(address(vat), address(gov));
        flop = new Flopper(address(vat), address(gov));
        gov.setOwner(address(flop));

        vow = new Vow(address(vat), address(flap), address(flop));

        pot = new Pot(address(vat));
        vat.rely(address(pot));
        pot.file("vow", address(vow));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        spot = new Spotter(address(vat));
        vat.file("Line",         rad(1000 ether));
        vat.rely(address(spot));

        end = new End();
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("vow", address(vow));
        end.file("pot", address(pot));
        end.file("spot", address(spot));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        spot.rely(address(end));
        pot.rely(address(end));
        cat.rely(address(end));
        flap.rely(address(vow));
        flop.rely(address(vow));

        jug        = new Jug(address(vat));
        reg        = new IlkRegistry(address(vat), address(cat), address(spot));
        osmMom     = new OsmMom();
        govGuard   = new MkrAuthority();
        flipperMom = new FlipperMom(address(cat));

        median = new Median();

        hevm.store(
            LOG,
            keccak256(abi.encode(address(this), uint256(0))), // Grant auth to test contract
            bytes32(uint256(1))
        );

        log = ChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F); // Deployed chain

        log.setAddress("MCD_VAT",     address(vat));
        log.setAddress("MCD_CAT",     address(cat));
        log.setAddress("MCD_JUG",     address(jug));
        log.setAddress("MCD_POT",     address(pot));
        log.setAddress("MCD_VOW",     address(vow));
        log.setAddress("MCD_SPOT",    address(spot));
        log.setAddress("MCD_FLAP",    address(flap));
        log.setAddress("MCD_FLOP",    address(flop));
        log.setAddress("MCD_END",     address(end));
        log.setAddress("ILK_REG",     address(reg));
        log.setAddress("OSM_MOM",     address(osmMom));
        log.setAddress("GOV_GUARD",   address(govGuard));
        log.setAddress("FLIPPER_MOM", address(flipperMom));

        // lib = new DssExecLib();

        // action = new DssAction(address(lib));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity_mainnet() public {
        assertTrue(true);
    }

    // /**********************/
    // /*** Authorizations ***/
    // /**********************/

    // function test_authorize() public {
    //     assertEq(vat.wards(address(1)), 0);
    //     action.authorize(address(vat), address(1));
    //     assertEq(vat.wards(address(1)), 1);
    // }

    // function test_deauthorize() public {
    //     assertEq(vat.wards(address(1)), 0);
    //     action.authorize(address(vat), address(1));
    //     assertEq(vat.wards(address(1)), 1);

    //     action.deauthorize(address(vat), address(1));
    //     assertEq(vat.wards(address(1)), 0);
    // }

    // /**************************/
    // /*** Accumulating Rates ***/
    // /**************************/

    // function test_accumulateDSR() public {
    //     uint256 beforeChai = pot.chai();
    //     hevm.warp(START_TIME + 1 days);
    //     action.accumulateDSR();
    //     uint256 afterChai = pot.chai();

    //     assertTrue(afterChai - beforeChai > 0);
    // }

    // function test_accumulateCollateralStabilityFees() public {
    //     (, uint256 beforeRate,,,) = vat.ilks("gold");
    //     hevm.warp(START_TIME + 1 days);
    //     action.accumulateCollateralStabilityFees("gold");
    //     (, uint256 afterRate,,,) = vat.ilks("gold");

    //     assertTrue(afterRate - beforeRate > 0);
    // }

    // /*********************/
    // /*** Price Updates ***/
    // /*********************/

    // function test_updateCollateralPrice() public {
    //     // TODO
    // }

    // /****************************/
    // /*** System Configuration ***/
    // /****************************/

    // function test_setContract() public {
    //     action.setContract(address(jug), "vow", address(1));
    //     assertEq(jug.vow(), address(1));

    //     // TODO per ilk?
    // }

    // /******************************/
    // /*** System Risk Parameters ***/
    // /******************************/

    // function test_setGlobalDebtCeiling() public {
    //     action.setGlobalDebtCeiling(100 * MILLION); // $100,000,000
    //     assertEq(vat.Line(), 100 * MILLION * RAD);  // Fixes precision
    // }

    // function test_setDSR() public {
    //     uint256 rate = 1000000001243680656318820312;
    //     action.setDSR(rate);
    //     assertEq(pot.dsr(), rate);
    // }

    // function test_setSuruplusAuctionAmount() public {
    //     action.setSurplusAuctionAmount(100 * THOUSAND);
    //     assertEq(vow.bump(), 100 * THOUSAND * RAD);
    // }

    // function test_setSurplusBuffer() public {
    //     action.setSurplusBuffer(1 * MILLION);
    //     assertEq(vow.hump(), 1 * MILLION * RAD);
    // }

    // function test_setMinSurplusAuctionBidIncrease() public {
    //     action.setMinSurplusAuctionBidIncrease(5250); // 5.25%
    //     assertEq(flap.beg(), 5.25 ether); // WAD pct
    // }

    // function test_setSurplusAuctionBidDuration() public {
    //     action.setSurplusAuctionBidDuration(12 hours); 
    //     assertEq(flap.ttl(), 12 hours);
    // }

    // function test_setSurplusAuctionDuration() public {
    //     action.setSurplusAuctionDuration(12 hours); 
    //     assertEq(flap.tau(), 12 hours);
    // }

    // function test_setDebtAuctionDelay() public {
    //     action.setDebtAuctionDelay(12 hours); 
    //     assertEq(vow.wait(), 12 hours);
    // }

    // function test_setDebtAuctionDAIAmount() public {
    //     action.setDebtAuctionDAIAmount(100 * THOUSAND); 
    //     assertEq(vow.sump(), 100 * THOUSAND * RAD);
    // }

    // function test_setDebtAuctionMKRAmount() public {
    //     action.setDebtAuctionMKRAmount(100); 
    //     assertEq(vow.dump(), 100 * RAD);
    // }

    // function test_setMinDebtAuctionBidIncrease() public {
    //     action.setMinDebtAuctionBidIncrease(5250); // 5.25%
    //     assertEq(flop.beg(), 5.25 ether / 100); // WAD pct
    // }

    // function test_setDebtAuctionBidDuration() public {
    //     action.setDebtAuctionBidDuration(12 hours); 
    //     assertEq(flop.ttl(), 12 hours);
    // }

    // function test_setDebtAuctionDuration() public {
    //     action.setDebtAuctionDuration(12 hours); 
    //     assertEq(flop.tau(), 12 hours);
    // }

    // function test_setDebtAuctionBidIncreaseRate() public {
    //     action.setDebtAuctionBidIncreaseRate(5250); 
    //     assertEq(flop.pct(), 105.25 ether / 100); // WAD pct
    // }

    // function test_setMaxTotalDAILiquidationAmount() public {
    //     action.setMaxTotalDAILiquidationAmount(50 * MILLION); 
    //     assertEq(cat.box(), 50 * MILLION * RAD); // WAD pct
    // }

    // function test_setEmergencyShutdownProcessingTime() public {
    //     action.setEmergencyShutdownProcessingTime(12 hours); 
    //     assertEq(end.wait(), 12 hours); 
    // }

    // function test_setGlobalStabilityFee() public {
    //     uint256 rate = 1000000001243680656318820312;
    //     action.setGlobalStabilityFee(rate); 
    //     assertEq(jug.base(), rate); 
    // }

    // function test_setDAIReferenceValue() public {
    //     action.setDAIReferenceValue(1005); // $1.005
    //     assertEq(spot.par(), ray(1.005 ether)); 
    // }

    // /*****************************/
    // /*** Collateral Management ***/
    // /*****************************/
    
    // function test_setIlkDebtCeiling() public {
    //     action.setIlkDebtCeiling("gold", 100 * MILLION);
    //     (,,, uint256 line,) = vat.ilks("gold"); 
    //     assertEq(line, 100 * MILLION * RAD); 
    // }

    // function test_setIlkMinVaultAmount() public {
    //     action.setIlkMinVaultAmount("gold", 100);
    //     (,,,, uint256 dust) = vat.ilks("gold"); 
    //     assertEq(dust, 100 * RAD); 
    // }

    // function test_setIlkLiquidationPenalty() public {
    //     action.setIlkLiquidationPenalty("gold", 13250); // 13.25%
    //     (, uint256 chop,) = cat.ilks("gold"); 
    //     assertEq(chop, 113.25 ether / 100);  // WAD pct 113.25%
    // }

    // function test_setIlkMaxLiquidationAmount() public {
    //     action.setIlkMaxLiquidationAmount("gold", 50 * THOUSAND);
    //     (,, uint256 dunk) = cat.ilks("gold"); 
    //     assertEq(dunk, 50 * THOUSAND * RAD); 
    // }

    // function test_setIlkLiquidationRatio() public {
    //     action.setIlkLiquidationRatio("gold", 150000); // 150%
    //     (, uint256 mat) = spot.ilks("gold"); 
    //     assertEq(mat, ray(150 ether / 100)); // RAY pct
    // }

    // function test_setIlkMinAuctionBidIncrease() public {
    //     action.setIlkMinAuctionBidIncrease("gold", 5000); // 5%
    //     assertEq(flip.beg(), 5 ether / 100); // WAD pct
    // }

    // function test_setIlkBidDuration() public {
    //     action.setIlkBidDuration("gold", 6 hours); 
    //     assertEq(flip.ttl(), 6 hours);
    // }

    // function test_setIlkAuctionDuration() public {
    //     action.setIlkAuctionDuration("gold", 6 hours); 
    //     assertEq(flip.tau(), 6 hours);
    // }

    // function test_setIlkStabilityFee() public {
    //     hevm.warp(START_TIME + 1 days);
    //     action.setIlkStabilityFee("gold", 1000000001243680656318820312); 
    //     (uint256 duty, uint256 rho) = jug.ilks("gold");
    //     assertEq(duty, 1000000001243680656318820312);
    //     assertEq(rho, START_TIME + 1 days);
    // }

    // /***********************/
    // /*** Core Management ***/
    // /***********************/

    // function test_updateCollateralActionContract() public {
    //     (,,, Flipper flip) = ilks("gold");
    //     Flipper newFlip = new Flipper(address(vat), address(cat), "gold");
    //     action.updateCollateralActionContract("gold", address(flip), address(1)); 

    //     (address catFlip,,) = cat.ilks("gold");
    //     assertEq(catFlip, address(1));

    //     assertEq(newFlip.wards(address(cat)),        1);
    //     assertEq(newFlip.wards(address(end)),        1);
    //     assertEq(newFlip.wards(address(flipperMom)), 1);

    //     assertEq(flip.wards(address(cat)),        0);
    //     assertEq(flip.wards(address(end)),        0);
    //     assertEq(flip.wards(address(flipperMom)), 0);

    //     assertEq(newFlip.beg(), flip.beg());
    //     assertEq(newFlip.ttl(), flip.ttl());
    //     assertEq(newFlip.tau(), flip.tau());
    // }

    // function test_updateSurplusAuctionContract() public {
    //     Flapper newFlap = new Flapper(address(vat), address(gov));
    //     action.updateSurplusAuctionContract("gold", address(flip), address(1)); 
        
    //     assertq(vow.flapper(), address(newFlap));

    //     assertEq(newFlap.wards(address(vow)), 1);
    //     assertEq(flap.wards(address(vow)),    0);

    //     assertEq(newFlap.beg(), flap.beg());
    //     assertEq(newFlap.ttl(), flap.ttl());
    //     assertEq(newFlap.tau(), flap.tau());
    // }

    // function test_updateSurplusAuctionContract() public {
    //     Flopper newFlop = new Flopper(address(vat), address(gov));
    //     action.updateSurplusAuctionContract("gold", address(flip), address(1)); 
        
    //     assertq(vow.flopper(), address(newFlop));

    //     assertEq(newFlop.wards(address(vow)),          1);
    //     assertEq(vat.wards(address(newFlop)),          1);
    //     assertEq(mkrAuthority.wards(address(newFlop)), 1);

    //     assertEq(flop.wards(address(vow)),          0);
    //     assertEq(vat.wards(address(flop)),          0);
    //     assertEq(mkrAuthority.wards(address(flop)), 0);

    //     assertEq(newFlop.beg(), flop.beg());
    //     assertEq(newFlop.ttl(), flop.ttl());
    //     assertEq(newFlop.tau(), flop.tau());
    //     assertEq(newFlop.pad(), flop.pad());
    // }

    // /*************************/
    // /*** Oracle Management ***/
    // /*************************/

    // function test_addWritersToMedianWhitelist() public {
    //     address[] memory feeds = new address[](2);
    //     feeds[0] = address(1);
    //     feeds[1] = address(2);

    //     assertEq(median.orcl(address(1)), 0);
    //     assertEq(median.orcl(address(2)), 0);
    //     action.addWritersToMedianWhitelist(address(median), feeds);
    //     assertEq(median.orcl(address(1)), 1);
    //     assertEq(median.orcl(address(2)), 1);
    // }

    // function test_removeWritersFromMedianWhitelist() public {
    //     address[] memory feeds = new address[](2);
    //     feeds[0] = address(1);
    //     feeds[1] = address(2);

    //     assertEq(median.orcl(address(1)), 0);
    //     assertEq(median.orcl(address(2)), 0);
    //     action.addWritersToMedianWhitelist(address(median), feeds);
    //     assertEq(median.orcl(address(1)), 1);
    //     assertEq(median.orcl(address(2)), 1);
    //     action.removeWritersFromMedianWhitelist(address(median), feeds);
    //     assertEq(median.orcl(address(1)), 0);
    //     assertEq(median.orcl(address(2)), 0);
    // }

    // function test_addReadersToMedianWhitelist() public {
    //     address[] memory readers = new address[](2);
    //     readers[0] = address(1);
    //     readers[1] = address(2);

    //     assertEq(median.bud(address(1)), 0);
    //     assertEq(median.bud(address(2)), 0);
    //     action.addReadersToMedianWhitelist(address(median), readers);
    //     assertEq(median.bud(address(1)), 1);
    //     assertEq(median.bud(address(2)), 1);
    // }

    // function test_removeReadersFromMedianWhitelist() public {
    //     address[] memory readers = new address[](2);
    //     readers[0] = address(1);
    //     readers[1] = address(2);

    //     assertEq(median.bud(address(1)), 0);
    //     assertEq(median.bud(address(2)), 0);
    //     action.addReadersToMedianWhitelist(address(median), readers);
    //     assertEq(median.bud(address(1)), 1);
    //     assertEq(median.bud(address(2)), 1);
    //     action.removeReadersFromMedianWhitelist(address(median), readers);
    //     assertEq(median.bud(address(1)), 0);
    //     assertEq(median.bud(address(2)), 0);
    // }

    // function test_addReaderToMedianWhitelist() public {
    //     address reader = address(1);

    //     assertEq(median.bud(address(1)), 0);
    //     action.addReaderToMedianWhitelist(address(median), feeds);
    //     assertEq(median.bud(address(1)), 1);
    // }

    // function test_removeReaderFromMedianWhitelist() public {
    //     address reader = address(1);

    //     assertEq(median.bud(address(1)), 0);
    //     action.addReaderToMedianWhitelist(address(median), feeds);
    //     assertEq(median.bud(address(1)), 1);
    //     action.removeReaderFromMedianWhitelist(address(median), feeds);
    //     assertEq(median.bud(address(1)), 0);
    // }

    // function test_setMedianWritersQuorum() public {
    //     action.setMedianWritersQuorum(address(median), 11);
    //     assertEq(median.bar(), 11);
    // }

    // function test_addReaderToOSMWhitelist() public {
    //     (DSValue pip,,,) = ilks("gold");
    //     address reader = address(1);

    //     assertEq(OsmAbstract(address(pip)).bud(address(1)), 0);
    //     action.addReaderToOSMWhitelist(address(pip), feeds);
    //     assertEq(OsmAbstract(address(pip)).bud(address(1)), 1);
    // }

    // function test_removeReaderFromOSMWhitelist() public {
    //     (DSValue pip,,,) = ilks("gold");
    //     address reader = address(1);

    //     assertEq(OsmAbstract(address(pip)).bud(address(1)), 0);
    //     action.addReaderToOSMWhitelist(address(pip), feeds);
    //     assertEq(OsmAbstract(address(pip)).bud(address(1)), 1);
    //     action.removeReaderFromOSMWhitelist(address(pip), feeds);
    //     assertEq(OsmAbstract(address(pip)).bud(address(1)), 0);
    // }

    // function test_allowOSMFreeze() public {
    //     (DSValue pip,,,) = ilks("gold");
    //     action.allowOSMFreeze(address(pip), "gold");
    //     assertEq(osmMom.osms("gold"), address(pip));
    // }

    // /*****************************/
    // /*** Collateral Onboarding ***/
    // /*****************************/

    // function test_addNewCollateral_no_liquidations_no_osm() public {
    //     DSToken token     = new DSToken("silver");
    //     GemJoin tokenJoin = new GemJoin(address(vat), name, address(token));
    //     Flipper tokenFlip = new Flipper(address(vat), address(cat), name);
    //     DSValue tokenPip  = new DSValue();

    //     bytes32 ilk = "silver";

    //     action.addNewCollateral(
    //         "silver",
    //         [
    //             address(token),
    //             address(tokenJoin),
    //             address(tokenFlip),
    //             address(tokenPip)
    //         ],
    //         false, // Not liquidatable
    //         true,  // pip == osm
    //         100 * MILLION,
    //         100,
    //         50 * THOUSAND,
    //         13000,
    //         1000000001243680656318820312,
    //         5000,
    //         6 hours,
    //         6 hours,
    //         150000
    //     );

    //     assertEq(vat.wards(address(tokenJoin)), 1);
    //     assertEq(cat.wards(address(tokenFlip)), 1);

    //     assertEq(tokenFlip.wards(address(cat)),        1);
    //     assertEq(tokenFlip.wards(address(end)),        1);
    //     assertEq(tokenFlip.wards(address(flipperMom)), 0);

    //     (, uint256 rate, uint256 spot, uint256 line, uint256 dust) = vat.ilks(ilk);
    //     assertEq(line, 100 * MILLION * RAD); 
    //     assertEq(dust, 100 * RAD); 
    //     assertEq(dunk, 50 * THOUSAND * RAD); 
    //     assertEq(chop, 113 ether / 100);  // WAD pct 113%

    //     (uint256 duty, uint256 rho) = jug.ilks("gold");
    //     assertEq(duty, 1000000001243680656318820312);
    //     assertEq(rho, START_TIME);

    //     assertEq(flip.beg(), 5 ether / 100); // WAD pct
    //     assertEq(flip.ttl(), 6 hours);
    //     assertEq(flip.tau(), 6 hours);

    //     (PipLike pip, uint256 mat) = spot.ilks(ilk);
    //     assertEq(mat, ray(150 ether / 100)); // RAY pct

    //     bytes32[] memory ilkList = reg.list();
    //     assertEq(ilkList[ilkList.length - 1], ilk);
    // }

    // function test_addNewCollateral_with_liquidations_no_osm() public {
    //     DSToken token     = new DSToken("silver");
    //     GemJoin tokenJoin = new GemJoin(address(vat), name, address(token));
    //     Flipper tokenFlip = new Flipper(address(vat), address(cat), name);
    //     DSValue tokenPip  = new DSValue();

    //     bytes32 ilk = "silver";

    //     action.addNewCollateral(
    //         "silver",
    //         [
    //             address(token),
    //             address(tokenJoin),
    //             address(tokenFlip),
    //             address(tokenPip)
    //         ],
    //         false, // Not liquidatable
    //         true,  // pip == osm
    //         100 * MILLION,
    //         100,
    //         50 * THOUSAND,
    //         13000,
    //         1000000001243680656318820312,
    //         5000,
    //         6 hours,
    //         6 hours,
    //         150000
    //     );

    //     assertEq(vat.wards(address(tokenJoin)), 1);
    //     assertEq(cat.wards(address(tokenFlip)), 1);

    //     assertEq(tokenFlip.wards(address(cat)),        1);
    //     assertEq(tokenFlip.wards(address(end)),        1);
    //     assertEq(tokenFlip.wards(address(flipperMom)), 1);

    //     (, uint256 rate, uint256 spot, uint256 line, uint256 dust) = vat.ilks(ilk);
    //     assertEq(line, 100 * MILLION * RAD); 
    //     assertEq(dust, 100 * RAD); 
    //     assertEq(dunk, 50 * THOUSAND * RAD); 
    //     assertEq(chop, 113 ether / 100);  // WAD pct 113%

    //     (uint256 duty, uint256 rho) = jug.ilks("gold");
    //     assertEq(duty, 1000000001243680656318820312);
    //     assertEq(rho, START_TIME);

    //     assertEq(flip.beg(), 5 ether / 100); // WAD pct
    //     assertEq(flip.ttl(), 6 hours);
    //     assertEq(flip.tau(), 6 hours);

    //     (PipLike pip, uint256 mat) = spot.ilks(ilk);
    //     assertEq(mat, ray(150 ether / 100)); // RAY pct

    //     bytes32[] memory ilkList = reg.list();
    //     assertEq(ilkList[ilkList.length - 1], ilk);
    // }

    // function test_addNewCollateral_with_liquidations_no_osm() public {
    //     DSToken token     = new DSToken("silver");
    //     GemJoin tokenJoin = new GemJoin(address(vat), name, address(token));
    //     Flipper tokenFlip = new Flipper(address(vat), address(cat), name);
    //     DSValue tokenPip  = new DSValue();

    //     bytes32 ilk = "silver";

    //     action.addNewCollateral(
    //         "silver",
    //         [
    //             address(token),
    //             address(tokenJoin),
    //             address(tokenFlip),
    //             address(tokenPip)
    //         ],
    //         false, // Not liquidatable
    //         true,  // pip == osm
    //         100 * MILLION,
    //         100,
    //         50 * THOUSAND,
    //         13000,
    //         1000000001243680656318820312,
    //         5000,
    //         6 hours,
    //         6 hours,
    //         150000
    //     );

    //     assertEq(vat.wards(address(tokenJoin)), 1);
    //     assertEq(cat.wards(address(tokenFlip)), 1);

    //     assertEq(tokenFlip.wards(address(cat)),        1);
    //     assertEq(tokenFlip.wards(address(end)),        1);
    //     assertEq(tokenFlip.wards(address(flipperMom)), 1);

    //     // TODO: OSM tests

    //     (, uint256 rate, uint256 spot, uint256 line, uint256 dust) = vat.ilks(ilk);
    //     assertEq(line, 100 * MILLION * RAD); 
    //     assertEq(dust, 100 * RAD); 
    //     assertEq(dunk, 50 * THOUSAND * RAD); 
    //     assertEq(chop, 113 ether / 100);  // WAD pct 113%

    //     (uint256 duty, uint256 rho) = jug.ilks("gold");
    //     assertEq(duty, 1000000001243680656318820312);
    //     assertEq(rho, START_TIME);

    //     assertEq(flip.beg(), 5 ether / 100); // WAD pct
    //     assertEq(flip.ttl(), 6 hours);
    //     assertEq(flip.tau(), 6 hours);

    //     (PipLike pip, uint256 mat) = spot.ilks(ilk);
    //     assertEq(mat, ray(150 ether / 100)); // RAY pct

    //     bytes32[] memory ilkList = reg.list();
    //     assertEq(ilkList[ilkList.length - 1], ilk);
    // }
}

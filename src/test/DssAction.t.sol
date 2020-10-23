// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssAction.sol -- DSS Executive Spell Action Tests
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {ChainLog}         from "dss-chain-log/ChainLog.sol";
import {OsmMom}           from "osm-mom/OsmMom.sol";
import {MkrAuthority}     from "mkr-authority/MkrAuthority.sol";
import {IlkRegistry}      from "ilk-registry/IlkRegistry.sol";
import {FlipperMom}       from "flipper-mom/FlipperMom.sol";
import {Median}           from "median/median.sol";
import {OSM}              from 'osm/osm.sol';
import {OsmAbstract}      from "dss-interfaces/Interfaces.sol";
import {DSProxyFactory,
        DSProxy}          from "ds-proxy/proxy.sol";

import {Vat}              from 'dss/vat.sol';
import {Cat}              from 'dss/cat.sol';
import {Vow}              from 'dss/vow.sol';
import {Pot}              from 'dss/pot.sol';
import {Jug}              from 'dss/jug.sol';
import {Flipper}          from 'dss/flip.sol';
import {Flapper}          from 'dss/flap.sol';
import {Flopper}          from 'dss/flop.sol';
import {GemJoin}          from 'dss/join.sol';
import {End}              from 'dss/end.sol';
import {Spotter}          from 'dss/spot.sol';

import {DssTestAction}    from './DssTestAction.sol';
import {DssExecLib}       from '../DssExecLib.sol';

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

contract ActionTest is DSTest {
    Hevm hevm;

    Vat   vat;
    End   end;
    Vow   vow;
    Pot   pot;
    Jug   jug;
    Cat   cat;

    DSToken gov;

    IlkRegistry  reg;
    Median median;
    OsmMom       osmMom;
    MkrAuthority govGuard;
    FlipperMom flipperMom;

    ChainLog log;

    Spotter spot;
    Flapper flap;
    Flopper flop;

    DssTestAction action;
    DssExecLib lib;

    struct Ilk {
        DSValue pip;
        OSM     osm;
        DSToken gem;
        GemJoin gemA;
        Flipper flip;
    }

    mapping (bytes32 => Ilk) ilks;

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

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

    function init_collateral(bytes32 name, address _action) internal returns (Ilk memory) {
        DSToken coin = new DSToken(name);
        coin.mint(20 ether);

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        OSM osm = new OSM(address(pip));

        vat.init(name);
        GemJoin gemA = new GemJoin(address(vat), name, address(coin));

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
        cat.file("box", rad((10 ether) * MILLION));

        reg.add(address(gemA));

        flip.rely(_action);
        gemA.rely(_action);
        osm.rely(_action);

        ilks[name].pip = pip;
        ilks[name].osm = osm;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].flip = flip;


        return ilks[name];
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(START_TIME);

        vat = new Vat();
        gov = new DSToken('GOV');

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

        jug = new Jug(address(vat));
        vat.rely(address(jug));

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

        log.setAddress("MCD_VAT",      address(vat));
        log.setAddress("MCD_CAT",      address(cat));
        log.setAddress("MCD_JUG",      address(jug));
        log.setAddress("MCD_POT",      address(pot));
        log.setAddress("MCD_VOW",      address(vow));
        log.setAddress("MCD_SPOT",     address(spot));
        log.setAddress("MCD_FLAP",     address(flap));
        log.setAddress("MCD_FLOP",     address(flop));
        log.setAddress("MCD_END",      address(end));
        log.setAddress("ILK_REGISTRY", address(reg));
        log.setAddress("OSM_MOM",      address(osmMom));
        log.setAddress("GOV_GUARD",    address(govGuard));
        log.setAddress("FLIPPER_MOM",  address(flipperMom));

        lib = new DssExecLib();

        action = new DssTestAction(address(lib));

        init_collateral("gold", address(action));

        vat.rely(address(action));
        spot.rely(address(action));
        cat.rely(address(action));
        vow.rely(address(action));
        end.rely(address(action));
        pot.rely(address(action));
        jug.rely(address(action));
        flap.rely(address(action));
        flop.rely(address(action));
        median.rely(address(action));
        log.rely(address(action));

        flipperMom.setOwner(address(action));
        osmMom.setOwner(address(action));

        govGuard.setRoot(address(action));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    // /**********************/
    // /*** Authorizations ***/
    // /**********************/

    function test_authorize() public {
        assertEq(vat.wards(address(1)), 0);
        action.authorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 1);
    }

    function test_deauthorize() public {
        assertEq(vat.wards(address(1)), 0);
        action.authorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 1);

        action.deauthorize_test(address(vat), address(1));
        assertEq(vat.wards(address(1)), 0);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/

    function test_setAddress() public {
        bytes32 ilk = "silver";
        action.setChangelogAddress_test(ilk, address(this));
        assertEq(log.getAddress(ilk), address(this));
    }

    function test_setVersion() public {
        string memory version = "9001.0.0";
        action.setChangelogVersion_test(version);
        assertEq(log.version(), version);
    }

    function test_setIPFS() public {
        string memory ipfs = "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW";
        action.setChangelogIPFS_test(ipfs);
        assertEq(log.ipfs(), ipfs);
    }

    function test_setSHA256() public {
        string memory SHA256 = "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b";
        action.setChangelogSHA256_test(SHA256);
        assertEq(log.sha256sum(), SHA256);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/

    function test_accumulateDSR() public {
        uint256 beforeChi = pot.chi();
        action.setDSR_test(1000000001243680656318820312); // 4%
        hevm.warp(START_TIME + 1 days);
        action.accumulateDSR_test();
        uint256 afterChi = pot.chi();

        assertTrue(afterChi - beforeChi > 0);
    }

    function test_accumulateCollateralStabilityFees() public {
        (, uint256 beforeRate,,,) = vat.ilks("gold");
        action.setDSR_test(1000000001243680656318820312); // 4%
        hevm.warp(START_TIME + 1 days);
        action.accumulateCollateralStabilityFees_test("gold");
        (, uint256 afterRate,,,) = vat.ilks("gold");

        assertTrue(afterRate - beforeRate > 0);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/

    function test_updateCollateralPrice() public {
        uint256 _spot;

        (,, _spot,,) = vat.ilks("gold");
        assertEq(_spot, ray(3 ether));
        ilks["gold"].pip.poke(bytes32(10 * WAD));

        action.updateCollateralPrice_test("gold");

        (,, _spot,,) = vat.ilks("gold");
        assertEq(_spot, ray(5 ether)); // $5 at 200%
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/

    function test_setContract() public {
        action.setContract_test(address(jug), "vow", address(1));
        assertEq(jug.vow(), address(1));
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/

    function test_setGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 100 * MILLION * RAD);  // Fixes precision
    }

    function test_increaseGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // setup

        action.increaseGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 200 * MILLION * RAD);  // Fixes precision
    }

    function test_decreaseGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(300 * MILLION); // setup

        action.decreaseGlobalDebtCeiling_test(100 * MILLION); // 100,000,000 Dai
        assertEq(vat.Line(), 200 * MILLION * RAD);  // Fixes precision
    }

    function testFail_decreaseGlobalDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION); // setup

        action.decreaseGlobalDebtCeiling_test(101 * MILLION); // fail
    }

    function test_setDSR() public {
        uint256 rate = 1000000001243680656318820312;
        action.setDSR_test(rate);
        assertEq(pot.dsr(), rate);
    }

    function test_setSuruplusAuctionAmount() public {
        action.setSurplusAuctionAmount_test(100 * THOUSAND);
        assertEq(vow.bump(), 100 * THOUSAND * RAD);
    }

    function test_setSurplusBuffer() public {
        action.setSurplusBuffer_test(1 * MILLION);
        assertEq(vow.hump(), 1 * MILLION * RAD);
    }

    function test_setMinSurplusAuctionBidIncrease() public {
        action.setMinSurplusAuctionBidIncrease_test(525); // 5.25%
        assertEq(flap.beg(), 5.25 ether / 100); // WAD pct
    }

    function test_setSurplusAuctionBidDuration() public {
        action.setSurplusAuctionBidDuration_test(12 hours);
        assertEq(uint256(flap.ttl()), 12 hours);
    }

    function test_setSurplusAuctionDuration() public {
        action.setSurplusAuctionDuration_test(12 hours);
        assertEq(uint256(flap.tau()), 12 hours);
    }

    function test_setDebtAuctionDelay() public {
        action.setDebtAuctionDelay_test(12 hours);
        assertEq(vow.wait(), 12 hours);
    }

    function test_setDebtAuctionDAIAmount() public {
        action.setDebtAuctionDAIAmount_test(100 * THOUSAND);
        assertEq(vow.sump(), 100 * THOUSAND * RAD);
    }

    function test_setDebtAuctionMKRAmount() public {
        action.setDebtAuctionMKRAmount_test(100);
        assertEq(vow.dump(), 100 * WAD);
    }

    function test_setMinDebtAuctionBidIncrease() public {
        action.setMinDebtAuctionBidIncrease_test(525); // 5.25%
        assertEq(flop.beg(), 5.25 ether / 100); // WAD pct
    }

    function test_setDebtAuctionBidDuration() public {
        action.setDebtAuctionBidDuration_test(12 hours);
        assertEq(uint256(flop.ttl()), 12 hours);
    }

    function test_setDebtAuctionDuration() public {
        action.setDebtAuctionDuration_test(12 hours);
        assertEq(uint256(flop.tau()), 12 hours);
    }

    function test_setDebtAuctionMKRIncreaseRate() public {
        action.setDebtAuctionMKRIncreaseRate_test(525);
        assertEq(flop.pad(), 105.25 ether / 100); // WAD pct
    }

    function test_setMaxTotalDAILiquidationAmount() public {
        action.setMaxTotalDAILiquidationAmount_test(50 * MILLION);
        assertEq(cat.box(), 50 * MILLION * RAD); // WAD pct
    }

    function test_setEmergencyShutdownProcessingTime() public {
        action.setEmergencyShutdownProcessingTime_test(12 hours);
        assertEq(end.wait(), 12 hours);
    }

    function test_setGlobalStabilityFee() public {
        uint256 rate = 1000000001243680656318820312;
        action.setGlobalStabilityFee_test(rate);
        assertEq(jug.base(), rate);
    }

    function test_setDAIReferenceValue() public {
        action.setDAIReferenceValue_test(1005); // $1.005
        assertEq(spot.par(), ray(1.005 ether));
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/

    function test_setIlkDebtCeiling() public {
        action.setIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 100 * MILLION * RAD);
    }

    function test_increaseIlkDebtCeiling() public {
        action.setGlobalDebtCeiling_test(100 * MILLION);
        action.setIlkDebtCeiling_test("gold", 100 * MILLION); // Setup

        action.increaseIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 200 * MILLION * RAD);
        assertEq(vat.Line(), 200 * MILLION * RAD); // also increased
    }

    function test_decreaseIlkDebtCeiling() public {
        action.setGlobalDebtCeiling_test(300 * MILLION);
        action.setIlkDebtCeiling_test("gold", 300 * MILLION); // Setup

        action.decreaseIlkDebtCeiling_test("gold", 100 * MILLION);
        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 200 * MILLION * RAD);
        assertEq(vat.Line(), 200 * MILLION * RAD); // also decreased
    }

    function testFail_decreaseIlkDebtCeiling() public {
        action.setIlkDebtCeiling_test("gold", 100 * MILLION); // Setup

        action.decreaseIlkDebtCeiling_test("gold", 101 * MILLION); // Fail
    }

    function test_setIlkMinVaultAmount() public {
        action.setIlkMinVaultAmount_test("gold", 100);
        (,,,, uint256 dust) = vat.ilks("gold");
        assertEq(dust, 100 * RAD);
    }

    function test_setIlkLiquidationPenalty() public {
        action.setIlkLiquidationPenalty_test("gold", 1325); // 13.25%
        (, uint256 chop,) = cat.ilks("gold");
        assertEq(chop, 113.25 ether / 100);  // WAD pct 113.25%
    }

    function test_setIlkMaxLiquidationAmount() public {
        action.setIlkMaxLiquidationAmount_test("gold", 50 * THOUSAND);
        (,, uint256 dunk) = cat.ilks("gold");
        assertEq(dunk, 50 * THOUSAND * RAD);
    }

    function test_setIlkLiquidationRatio() public {
        action.setIlkLiquidationRatio_test("gold", 15000); // 150% in bp
        (, uint256 mat) = spot.ilks("gold");
        assertEq(mat, ray(150 ether / 100)); // RAY pct
    }

    function test_setIlkMinAuctionBidIncrease() public {
        action.setIlkMinAuctionBidIncrease_test("gold", 500); // 5%
        assertEq(ilks["gold"].flip.beg(), 5 * WAD / 100); // WAD pct
    }

    function test_setIlkBidDuration() public {
        action.setIlkBidDuration_test("gold", 6 hours);
        assertEq(uint256(ilks["gold"].flip.ttl()), 6 hours);
    }

    function test_setIlkAuctionDuration() public {
        action.setIlkAuctionDuration_test("gold", 6 hours);
        assertEq(uint256(ilks["gold"].flip.tau()), 6 hours);
    }

    function test_setIlkStabilityFee() public {
        hevm.warp(START_TIME + 1 days);
        action.setIlkStabilityFee_test("gold", 1000000001243680656318820312);
        (uint256 duty, uint256 rho) = jug.ilks("gold");
        assertEq(duty, 1000000001243680656318820312);
        assertEq(rho, START_TIME + 1 days);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/

    function test_updateCollateralAuctionContract() public {
        Flipper flip = ilks["gold"].flip;
        Flipper newFlip = new Flipper(address(vat), address(cat), "gold");
        newFlip.rely(address(action));
        action.updateCollateralAuctionContract_test("gold", address(newFlip), address(flip));

        (address catFlip,,) = cat.ilks("gold");
        assertEq(catFlip, address(newFlip));

        assertEq(newFlip.wards(address(cat)),        1);
        assertEq(newFlip.wards(address(end)),        1);
        assertEq(newFlip.wards(address(flipperMom)), 1);

        assertEq(flip.wards(address(cat)),        0);
        assertEq(flip.wards(address(end)),        0);
        assertEq(flip.wards(address(flipperMom)), 0);

        assertEq(newFlip.beg(), flip.beg());
        assertEq(uint256(newFlip.ttl()), uint256(flip.ttl()));
        assertEq(uint256(newFlip.tau()), uint256(flip.tau()));
    }

    function test_updateSurplusAuctionContract() public {
        Flapper newFlap = new Flapper(address(vat), address(gov));
        newFlap.rely(address(action));
        action.updateSurplusAuctionContract_test(address(newFlap), address(flap));

        assertEq(address(vow.flapper()), address(newFlap));

        assertEq(newFlap.wards(address(vow)), 1);
        assertEq(flap.wards(address(vow)),    0);

        assertEq(newFlap.beg(), flap.beg());
        assertEq(uint256(newFlap.ttl()), uint256(flap.ttl()));
        assertEq(uint256(newFlap.tau()), uint256(flap.tau()));
    }

    function test_updateDebtAuctionContract() public {
        Flopper newFlop = new Flopper(address(vat), address(gov));
        newFlop.rely(address(action));
        action.updateDebtAuctionContract_test(address(newFlop), address(flop));

        assertEq(address(vow.flopper()), address(newFlop));

        assertEq(newFlop.wards(address(vow)),          1);
        assertEq(vat.wards(address(newFlop)),          1);
        assertEq(govGuard.wards(address(newFlop)), 1);

        assertEq(flop.wards(address(vow)),          0);
        assertEq(vat.wards(address(flop)),          0);
        assertEq(govGuard.wards(address(flop)), 0);

        assertEq(newFlop.beg(), flop.beg());
        assertEq(uint256(newFlop.ttl()), uint256(flop.ttl()));
        assertEq(uint256(newFlop.tau()), uint256(flop.tau()));
        assertEq(newFlop.pad(), flop.pad());
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/

    function test_addWritersToMedianWhitelist() public {
        address[] memory feeds = new address[](2);
        feeds[0] = address(this);   // Random addresses since 0x1 and 0x2 didnt work with bitshift
        feeds[1] = address(action); // Random addresses since 0x1 and 0x2 didnt work with bitshift

        assertEq(median.orcl(feeds[0]), 0);
        assertEq(median.orcl(feeds[1]), 0);
        action.addWritersToMedianWhitelist_test(address(median), feeds);
        assertEq(median.orcl(feeds[0]), 1);
        assertEq(median.orcl(feeds[1]), 1);
    }

    function test_removeWritersFromMedianWhitelist() public {
        address[] memory feeds = new address[](2);
        feeds[0] = address(this);   // Random addresses since 0x1 and 0x2 didnt work with bitshift
        feeds[1] = address(action); // Random addresses since 0x1 and 0x2 didnt work with bitshift

        assertEq(median.orcl(feeds[0]), 0);
        assertEq(median.orcl(feeds[1]), 0);
        action.addWritersToMedianWhitelist_test(address(median), feeds);
        assertEq(median.orcl(feeds[0]), 1);
        assertEq(median.orcl(feeds[1]), 1);
        action.removeWritersFromMedianWhitelist_test(address(median), feeds);
        assertEq(median.orcl(feeds[0]), 0);
        assertEq(median.orcl(feeds[1]), 0);
    }

    function test_addReadersToMedianWhitelist() public {
        address[] memory readers = new address[](2);
        readers[0] = address(1);
        readers[1] = address(2);

        assertEq(median.bud(address(1)), 0);
        assertEq(median.bud(address(2)), 0);
        action.addReadersToMedianWhitelist_test(address(median), readers);
        assertEq(median.bud(address(1)), 1);
        assertEq(median.bud(address(2)), 1);
    }

    function test_removeReadersFromMedianWhitelist() public {
        address[] memory readers = new address[](2);
        readers[0] = address(1);
        readers[1] = address(2);

        assertEq(median.bud(address(1)), 0);
        assertEq(median.bud(address(2)), 0);
        action.addReadersToMedianWhitelist_test(address(median), readers);
        assertEq(median.bud(address(1)), 1);
        assertEq(median.bud(address(2)), 1);
        action.removeReadersFromMedianWhitelist_test(address(median), readers);
        assertEq(median.bud(address(1)), 0);
        assertEq(median.bud(address(2)), 0);
    }

    function test_addReaderToMedianWhitelist() public {
        address reader = address(1);

        assertEq(median.bud(address(1)), 0);
        action.addReaderToMedianWhitelist_test(address(median), reader);
        assertEq(median.bud(address(1)), 1);
    }

    function test_removeReaderFromMedianWhitelist() public {
        address reader = address(1);

        assertEq(median.bud(address(1)), 0);
        action.addReaderToMedianWhitelist_test(address(median), reader);
        assertEq(median.bud(address(1)), 1);
        action.removeReaderFromMedianWhitelist_test(address(median), reader);
        assertEq(median.bud(address(1)), 0);
    }

    function test_setMedianWritersQuorum() public {
        action.setMedianWritersQuorum_test(address(median), 11);
        assertEq(median.bar(), 11);
    }

    function test_addReaderToOSMWhitelist() public {
        OSM osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToOSMWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
    }

    function test_removeReaderFromOSMWhitelist() public {
        OSM osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToOSMWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
        action.removeReaderFromOSMWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 0);
    }

    function test_allowOSMFreeze() public {
        OSM osm = ilks["gold"].osm;
        action.allowOSMFreeze_test(address(osm), "gold");
        assertEq(osmMom.osms("gold"), address(osm));
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function collateralOnboardingTest(bool liquidatable, bool isOsm, bool medianSrc) internal {
        bytes32 ilk = "silver";

        DSToken token     = new DSToken("silver");
        GemJoin tokenJoin = new GemJoin(address(vat), ilk, address(token));
        Flipper tokenFlip = new Flipper(address(vat), address(cat), ilk);
        DSValue tokenPip  = new DSValue();
        OSM     tokenOsm;

        if (isOsm) {
            tokenOsm = medianSrc ? new OSM(address(median)) : new OSM(address(tokenPip));
            tokenOsm.rely(address(action));
        }

        tokenFlip.rely(address(action));
        tokenJoin.rely(address(action));
        tokenFlip.deny(address(this));
        tokenJoin.deny(address(this));

        {
            address[] memory addresses = new address[](4);
            addresses[0] = address(token);
            addresses[1] = address(tokenJoin);
            addresses[2] = address(tokenFlip);
            addresses[3] = isOsm ? address(tokenOsm) : address(tokenPip);

            bool[] memory oracleSettings = new bool[](2);
            oracleSettings[0] = isOsm;
            oracleSettings[1] = medianSrc;

            uint256 globalLine = vat.Line();

            action.addNewCollateral_test(
                ilk,
                addresses,
                liquidatable,
                oracleSettings,
                100 * MILLION,                 // ilkDebtCeiling
                100,                           // minVaultAmount
                50 * THOUSAND,                 // maxLiquidationAmount
                1300,                          // liquidationPenalty
                1000000001243680656318820312,  // ilkStabilityFee
                500,                           // bidIncrease
                6 hours,                       // bidDuration
                6 hours,                       // auctionDuration
                15000                          // liquidationRatio
            );

            assertEq(vat.Line(), globalLine + 100 * MILLION * RAD);
        }

        assertEq(vat.wards(address(tokenJoin)), 1);
        assertEq(cat.wards(address(tokenFlip)), 1);

        assertEq(tokenFlip.wards(address(end)),        1);
        assertEq(tokenFlip.wards(address(flipperMom)), 1);

        if (!liquidatable) assertEq(tokenFlip.wards(address(cat)), 0);
        else               assertEq(tokenFlip.wards(address(cat)), 1);

        if (isOsm) {
            assertEq(tokenOsm.wards(address(osmMom)), 1);
            assertEq(tokenOsm.bud(address(spot)),     1);
            assertEq(tokenOsm.bud(address(end)),      1);

            if (medianSrc) assertEq(median.bud(address(tokenOsm)),   1);

            assertEq(osmMom.osms(ilk), address(tokenOsm));
        }

        {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
            assertEq(line, 100 * MILLION * RAD);
            assertEq(dust, 100 * RAD);
            assertEq(dunk, 50 * THOUSAND * RAD);
            assertEq(chop, 113 ether / 100);  // WAD pct 113%

            (uint256 duty, uint256 rho) = jug.ilks(ilk);
            assertEq(duty, 1000000001243680656318820312);
            assertEq(rho, START_TIME);
        }

        {
            assertEq(tokenFlip.beg(), 5 * WAD / 100); // WAD pct
            assertEq(uint256(tokenFlip.ttl()), 6 hours);
            assertEq(uint256(tokenFlip.tau()), 6 hours);

            (, uint256 mat) = spot.ilks(ilk);
            assertEq(mat, ray(150 ether / 100)); // RAY pct

            bytes32[] memory ilkList = reg.list();
            assertEq(ilkList[ilkList.length - 1], ilk);
        }
    }

    function test_addNewCollateral_case1() public {
        collateralOnboardingTest(true, true, true);      // Liquidations: ON,  PIP == OSM, osmSrc == median
    }
    function test_addNewCollateral_case2() public {
        collateralOnboardingTest(true, true, false);     // Liquidations: ON,  PIP == OSM, osmSrc != median
    }
    function test_addNewCollateral_case3() public {
        collateralOnboardingTest(true, false, false);    // Liquidations: ON,  PIP != OSM, osmSrc != median
    }
    function test_addNewCollateral_case4() public {
        collateralOnboardingTest(false, true, true);     // Liquidations: OFF, PIP == OSM, osmSrc == median
    }
    function test_addNewCollateral_case5() public {
        collateralOnboardingTest(false, true, false);    // Liquidations: OFF, PIP == OSM, osmSrc != median
    }
    function test_addNewCollateral_case6() public {
        collateralOnboardingTest(false, false, false);   // Liquidations: OFF, PIP != OSM, osmSrc != median
    }
}

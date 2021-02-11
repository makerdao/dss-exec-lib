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

pragma solidity ^0.6.11;

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
import {DssAutoLine}      from "dss-auto-line/DssAutoLine.sol";

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

import "../CollateralOpts.sol";
import {DssTestAction}    from './DssTestAction.sol';

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
    DssAutoLine autoLine;

    ChainLog log;

    Spotter spot;
    Flapper flap;
    Flopper flop;

    DssTestAction action;

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

        autoLine   = new DssAutoLine(address(vat));
        vat.rely(address(autoLine));

        median = new Median();

        hevm.store(
            LOG,
            keccak256(abi.encode(address(this), uint256(0))), // Grant auth to test contract
            bytes32(uint256(1))
        );

        log = ChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F); // Deployed chain

        log.setAddress("MCD_VAT",           address(vat));
        log.setAddress("MCD_CAT",           address(cat));
        log.setAddress("MCD_JUG",           address(jug));
        log.setAddress("MCD_POT",           address(pot));
        log.setAddress("MCD_VOW",           address(vow));
        log.setAddress("MCD_SPOT",          address(spot));
        log.setAddress("MCD_FLAP",          address(flap));
        log.setAddress("MCD_FLOP",          address(flop));
        log.setAddress("MCD_END",           address(end));
        log.setAddress("ILK_REGISTRY",      address(reg));
        log.setAddress("OSM_MOM",           address(osmMom));
        log.setAddress("GOV_GUARD",         address(govGuard));
        log.setAddress("FLIPPER_MOM",       address(flipperMom));
        log.setAddress("MCD_IAM_AUTO_LINE", address(autoLine));

        action = new DssTestAction(true);

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
        autoLine.rely(address(action));

        flipperMom.setOwner(address(action));
        osmMom.setOwner(address(action));

        govGuard.setRoot(address(action));
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function collateralOnboardingTest(bool liquidatable, bool isOsm, bool medianSrc) internal {

        bytes32 ilk = "silver";

        DSToken token     = new DSToken(ilk);
        GemJoin tokenJoin = new GemJoin(address(vat), ilk, address(token));
        Flipper tokenFlip = new Flipper(address(vat), address(cat), ilk);
        address tokenPip  = address(new DSValue());

        if (isOsm) {
            tokenPip = medianSrc ? address(new OSM(address(median))) : address(new OSM(address(tokenPip)));
            OSM(tokenPip).rely(address(action));
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
            addresses[3] = tokenPip;

            bool[] memory oracleSettings = new bool[](3);
            oracleSettings[0] = liquidatable;
            oracleSettings[1] = isOsm;
            oracleSettings[2] = medianSrc;

            uint256[] memory amounts = new uint256[](9);
            amounts[0] = 100 * MILLION;                // ilkDebtCeiling
            amounts[1] = 100;                          // minVaultAmount
            amounts[2] = 50 * THOUSAND;                // maxLiquidationAmount
            amounts[3] = 1300;                         // liquidationPenalty
            amounts[4] = 1000000001243680656318820312; // ilkStabilityFee
            amounts[5] = 500;                          // bidIncrease
            amounts[6] = 6 hours;                      // bidDuration
            amounts[7] = 6 hours;                      // auctionDuration
            amounts[8] = 15000;                        // liquidationRatio

            uint256 globalLine = vat.Line();

            action.addNewCollateral_test(
                ilk,
                addresses,
                oracleSettings,
                amounts
            );

            assertEq(vat.Line(), globalLine + 100 * MILLION * RAD);
        }

        {
        assertEq(vat.wards(address(tokenJoin)), 1);
        assertEq(cat.wards(address(tokenFlip)), 1);

        assertEq(tokenFlip.wards(address(end)),        1);
        assertEq(tokenFlip.wards(address(flipperMom)), 1);

        if (!liquidatable) assertEq(tokenFlip.wards(address(cat)), 0);
        else               assertEq(tokenFlip.wards(address(cat)), 1);
        }


        if (isOsm) {
          assertEq(OSM(tokenPip).wards(address(osmMom)), 1);
          assertEq(OSM(tokenPip).bud(address(spot)),     1);
          assertEq(OSM(tokenPip).bud(address(end)),      1);

           if (medianSrc) assertEq(median.bud(tokenPip),   1);
          assertEq(osmMom.osms(ilk), tokenPip);
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
            assertEq(tokenFlip.beg(), WAD + 5 * WAD / 100); // (1 + pct) * WAD
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

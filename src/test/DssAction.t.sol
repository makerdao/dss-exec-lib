// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssAction.sol -- DSS Executive Spell Action Tests
//
// Copyright (C) 2020-2022 Dai Foundation
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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {ChainLog}         from "dss-chain-log/ChainLog.sol";
import {OsmMom}           from "osm-mom/OsmMom.sol";
import {MkrAuthority}     from "mkr-authority/MkrAuthority.sol";
import {IlkRegistry}      from "ilk-registry/IlkRegistry.sol";
import {ClipperMom}       from "clipper-mom/ClipperMom.sol";
import {Median}           from "median/median.sol";
import {OSM}              from 'osm/osm.sol';
import {OsmAbstract,
        LerpAbstract}     from "dss-interfaces/Interfaces.sol";
import {UNIV2LPOracle}    from "univ2-lp-oracle/UNIV2LPOracle.sol";
import {DSProxyFactory,
        DSProxy}          from "ds-proxy/proxy.sol";
import {DssAutoLine}      from "dss-auto-line/DssAutoLine.sol";
import {LerpFactory}      from "dss-lerp/LerpFactory.sol";
import {DssDirectDepositAaveDai}
                          from "dss-direct-deposit/DssDirectDepositAaveDai.sol";
import {RwaLiquidationOracle}
                          from "MIP21-RWA-Example/RwaLiquidationOracle.sol";
import {AuthGemJoin}      from "dss-gem-joins/join-auth.sol";
import {RwaOutputConduit} from "MIP21-RWA-Example/RwaConduit.sol";
import {RwaUrn}           from "MIP21-RWA-Example/RwaUrn.sol";
import {RwaToken}         from "MIP21-RWA-Example/RwaToken.sol";

import {Vat}              from "dss/vat.sol";
import {Dog}              from "dss/dog.sol";
import {Cat}              from "dss/cat.sol";
import {Vow}              from "dss/vow.sol";
import {Pot}              from "dss/pot.sol";
import {Jug}              from "dss/jug.sol";
import {Clipper}          from "dss/clip.sol";
import {Flapper}          from "dss/flap.sol";
import {Flopper}          from "dss/flop.sol";
import {GemJoin,DaiJoin}  from "dss/join.sol";
import {End}              from "dss/end.sol";
import {Spotter}          from "dss/spot.sol";
import {Dai}              from "dss/dai.sol";
import {LinearDecrease,
        StairstepExponentialDecrease,
        ExponentialDecrease} from "dss/abaci.sol";

import "../CollateralOpts.sol";
import {DssTestAction, DssTestNoOfficeHoursAction}    from './DssTestAction.sol';

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
}

interface PipLike {
    function peek() external returns (bytes32, bool);
    function read() external returns (bytes32);
}

contract UniPairMock {
    address public token0; address public token1;
    constructor(address _token0, address _token1) public {
        token0 = _token0;  token1 = _token1;
    }
}

contract AaveMock {
    // https://docs.aave.com/developers/the-core-protocol/lendingpool
    function getReserveData(address dai) public view returns (
        uint256, uint128, uint128, uint128, uint128, uint128, uint40, address, address, address, address, uint8
    ) {
        address _dai = dai; // avoid stack too deep
        return (0,0,0,0,0,0,0, _dai, _dai, _dai, address(this), 0);
    }

    function getMaxVariableBorrowRate() public pure returns (uint256) {
        return type(uint256).max;
    }
}

contract ActionTest is DSTest {
    Hevm hevm;

    Vat         vat;
    End         end;
    Vow         vow;
    Pot         pot;
    Jug         jug;
    Dog         dog;
    Cat         cat;
    Dai         daiToken;
    DaiJoin     daiJoin;

    DSToken gov;

    IlkRegistry   reg;
    Median        median;
    OsmMom        osmMom;
    ClipperMom    clipperMom;
    MkrAuthority  govGuard;
    DssAutoLine   autoLine;
    LerpFactory   lerpFab;
    RwaLiquidationOracle rwaOracle;

    ChainLog clog;

    Spotter spot;
    Flapper flap;
    Flopper flop;

    DssTestAction action;

    struct Ilk {
        DSValue pip;
        OSM     osm;
        DSToken gem;
        GemJoin gemA;
        Clipper clip;
    }

    mapping (bytes32 => Ilk) ilks;

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    uint256 constant START_TIME = 604411200;
    string constant doc = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk";

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
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
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
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function init_collateral(bytes32 name, address _action) internal returns (Ilk memory) {
        DSToken coin = new DSToken("Token");
        coin.mint(20 ether);

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        OSM osm = new OSM(address(pip));
        osm.rely(address(clipperMom));

        vat.init(name);
        GemJoin gemA = new GemJoin(address(vat), name, address(coin));

        vat.file(name, "line", rad(1000 ether));

        coin.approve(address(gemA));
        coin.approve(address(vat));

        vat.rely(address(gemA));

        Clipper clip = new Clipper(address(vat), address(spot), address(dog), name);
        vat.hope(address(clip));
        clip.rely(address(end));
        clip.rely(address(dog));
        dog.rely(address(clip));
        dog.file(name, "clip", address(clip));
        dog.file(name, "chop", 1 ether);
        dog.file("Hole", rad((10 ether) * MILLION));

        reg.add(address(gemA));

        clip.rely(_action);
        gemA.rely(_action);
        osm.rely(_action);

        ilks[name].pip = pip;
        ilks[name].osm = osm;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].clip = clip;

        return ilks[name];
    }

    function init_rwa(
        bytes32 ilk,
        uint256 line,
        uint48 tau,
        uint256 duty,
        uint256 mat,
        address operator
    ) internal {
        uint256 val = rmul(rmul(line / RAY, mat), rpow(duty, 2 * 365 days, RAY));
        rwaOracle.init(ilk, val, doc, tau);
        (,address pip,,) = rwaOracle.ilks(ilk);
        spot.file(ilk, "pip", pip);
        vat.init(ilk);
        jug.init(ilk);
        string memory name = string(abi.encodePacked(ilk));
        RwaToken token = new RwaToken(name, name);
        AuthGemJoin join = new AuthGemJoin(address(vat), ilk, address(token));
        vat.rely(address(join));
        vat.rely(address(rwaOracle));
        vat.file(ilk, "line", line);
        vat.file("Line", vat.Line() + line);
        jug.file(ilk, "duty", duty);
        spot.file(ilk, "mat", mat);
        spot.poke(ilk);
        RwaOutputConduit out = new RwaOutputConduit(address(gov), address(daiToken));
        RwaUrn urn = new RwaUrn(address(vat), address(jug), address(join), address(daiJoin), address(out));
        join.rely(address(urn));
        urn.hope(operator);
        out.hope(operator);
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

        dog = new Dog(address(vat));
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        spot = new Spotter(address(vat));
        vat.file("Line",         rad(1000 ether));
        vat.rely(address(spot));

        jug = new Jug(address(vat));
        vat.rely(address(jug));

        daiToken = new Dai(1);
        daiJoin = new DaiJoin(address(vat), address(daiToken));
        daiToken.rely(address(daiJoin));
        daiToken.deny(address(this));

        end = new End();
        end.file("vat", address(vat));
        end.file("dog", address(dog));
        end.file("vow", address(vow));
        end.file("pot", address(pot));
        end.file("spot", address(spot));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        spot.rely(address(end));
        pot.rely(address(end));
        dog.rely(address(end));
        flap.rely(address(vow));
        flop.rely(address(vow));


        reg        = new IlkRegistry(address(vat), address(dog), address(cat), address(spot));
        osmMom     = new OsmMom();
        govGuard   = new MkrAuthority();
        clipperMom = new ClipperMom(address(dog));

        autoLine   = new DssAutoLine(address(vat));
        vat.rely(address(autoLine));

        lerpFab = new LerpFactory();

        median = new Median();

        rwaOracle = new RwaLiquidationOracle(address(vat), address(vow));

        hevm.store(
            LOG,
            keccak256(abi.encode(address(this), uint256(0))), // Grant auth to test contract
            bytes32(uint256(1))
        );
        clog = ChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F); // Deployed chain

        clog.setAddress("MCD_VAT",                  address(vat));
        clog.setAddress("MCD_DOG",                  address(dog));
        clog.setAddress("MCD_JUG",                  address(jug));
        clog.setAddress("MCD_POT",                  address(pot));
        clog.setAddress("MCD_VOW",                  address(vow));
        clog.setAddress("MCD_SPOT",                 address(spot));
        clog.setAddress("MCD_FLAP",                 address(flap));
        clog.setAddress("MCD_FLOP",                 address(flop));
        clog.setAddress("MCD_END",                  address(end));
        clog.setAddress("MCD_DAI",                  address(daiToken));
        clog.setAddress("MCD_JOIN_DAI",             address(daiJoin));
        clog.setAddress("ILK_REGISTRY",             address(reg));
        clog.setAddress("OSM_MOM",                  address(osmMom));
        clog.setAddress("GOV_GUARD",                address(govGuard));
        clog.setAddress("CLIPPER_MOM",              address(clipperMom));
        clog.setAddress("MCD_IAM_AUTO_LINE",        address(autoLine));
        clog.setAddress("LERP_FAB",                 address(lerpFab));
        clog.setAddress("MIP21_LIQUIDATION_ORACLE", address(rwaOracle));

        action = new DssTestAction();

        init_collateral("gold", address(action));
        init_rwa({
            ilk:      "6s",
            line:     20_000_000 * RAD,
            tau:      365 days,
            duty:     1000000000937303470807876289, // 3% APY
            mat:      105 * RAY / 100,
            operator: address(123)
        });

        vat.rely(address(action));
        spot.rely(address(action));
        dog.rely(address(action));
        vow.rely(address(action));
        end.rely(address(action));
        pot.rely(address(action));
        jug.rely(address(action));
        flap.rely(address(action));
        flop.rely(address(action));
        daiJoin.rely(address(action));
        median.rely(address(action));
        clog.rely(address(action));
        autoLine.rely(address(action));
        lerpFab.rely(address(action));
        rwaOracle.rely(address(action));

        clipperMom.setOwner(address(action));
        osmMom.setOwner(address(action));

        govGuard.setRoot(address(action));
    }

    // /******************************/
    // /*** OfficeHours Management ***/
    // /******************************/

    function test_canCast() public {
        assertTrue(action.canCast_test(1616169600, true));  // Friday   2021/03/19, 4:00:00 PM GMT

        assertTrue(action.canCast_test(1616169600, false)); // Friday   2021/03/19, 4:00:00 PM GMT
        assertTrue(action.canCast_test(1616256000, false)); // Saturday 2021/03/20, 4:00:00 PM GMT
    }

    function testFail_canCast() public {
        assertTrue(action.canCast_test(1616256000, true)); // Saturday 2021/03/20, 4:00:00 PM GMT
    }

    function test_nextCastTime() public {
        assertEq(action.nextCastTime_test(1616169600, 1616169600, true), 1616169600);
        assertEq(action.nextCastTime_test(1616169600, 1616169600, false), 1616169600);

        assertEq(action.nextCastTime_test(1616256000, 1616256000, true), 1616421600);
        assertEq(action.nextCastTime_test(1616256000, 1616256000, false), 1616256000);
    }

    function testFail_nextCastTime_eta_zero() public view {
        action.nextCastTime_test(0, 1616256000, false);
    }

    function testFail_nextCastTime_ts_zero() public view {
        action.nextCastTime_test(1616256000, 0, false);
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

    function test_setAuthority() public {
        assertEq(clipperMom.authority(), address(0));
        action.setAuthority_test(address(clipperMom), address(1));
        assertEq(clipperMom.authority(), address(1));
    }

    function test_delegateVat() public {
        assertEq(vat.can(address(action), address(1)), 0);
        action.delegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 1);
    }

    function test_undelegateVat() public {
        assertEq(vat.can(address(action), address(1)), 0);
        action.delegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 1);

        action.undelegateVat_test(address(1));
        assertEq(vat.can(address(action), address(1)), 0);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/

    function test_setAddress() public {
        bytes32 ilk = "silver";
        action.setChangelogAddress_test(ilk, address(this));
        assertEq(clog.getAddress(ilk), address(this));
    }

    function test_setVersion() public {
        string memory version = "9001.0.0";
        action.setChangelogVersion_test(version);
        assertEq(clog.version(), version);
    }

    function test_setIPFS() public {
        string memory ipfs = "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW";
        action.setChangelogIPFS_test(ipfs);
        assertEq(clog.ipfs(), ipfs);
    }

    function test_setSHA256() public {
        string memory SHA256 = "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b";
        action.setChangelogSHA256_test(SHA256);
        assertEq(clog.sha256sum(), SHA256);
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
        assertEq(flap.beg(), 1 ether + 5.25 ether / 100); // (1 + pct) * WAD
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
        assertEq(flop.beg(), 1 ether + 5.25 ether / 100); // (1 + pct) * WAD
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
        assertEq(dog.Hole(), 50 * MILLION * RAD); // WAD pct
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

    function test_setRWAIlkDebtCeiling() public {
        action.setRWAIlkDebtCeiling_test("6s", 50 * MILLION, 55 * MILLION);
        (,,, uint256 line,) = vat.ilks("6s");
        assertEq(line, 50 * MILLION * RAD);
        (,address pip,,) = rwaOracle.ilks("6s");
        uint256 price = uint256(PipLike(pip).read());
        assertEq(price, 55 * MILLION * WAD);
    }

    function test_setIlkAutoLineParameters() public {
        action.setIlkAutoLineParameters_test("gold", 150 * MILLION, 5 * MILLION, 10000); // Setup

        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 1000 * RAD); // does not change line

        autoLine.exec("gold");
        (,,, line,) = vat.ilks("gold");
        assertEq(line, 5 * MILLION * RAD); // Change to match the gap
    }

    function test_setIlkAutoLineDebtCeiling() public {
        action.setIlkAutoLineParameters_test("gold", 1, 5 * MILLION, 10000); // gap and ttl must be configured already
        action.setIlkAutoLineDebtCeiling_test("gold", 150 * MILLION); // Setup

        (,,, uint256 line,) = vat.ilks("gold");
        assertEq(line, 1000 * RAD); // does not change line

        autoLine.exec("gold");
        (,,, line,) = vat.ilks("gold");
        assertEq(line, 5 * MILLION * RAD); // Change to match the gap
    }

    function test_setRemoveIlkFromAutoLine() public {
        action.setIlkAutoLineParameters_test("gold", 100 * MILLION, 5 * MILLION, 10000); // gap and ttl must be configured already
        action.removeIlkFromAutoLine_test("gold");

        assertEq(autoLine.exec("gold"), 1000 * RAD);
    }

    function test_setIlkMinVaultAmountLt() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 1);
        (,,,, uint256 dust) = vat.ilks("gold");
        assertEq(dust, 1 * RAD);
    }

    function test_setIlkMinVaultAmountEq() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 100);
        (,,,, uint256 dust) = vat.ilks("gold");
        assertEq(dust, 100 * RAD);

        action.setIlkMaxLiquidationAmount_test("gold", 0);
        action.setIlkMinVaultAmount_test("gold", 0);
        (,,,, dust) = vat.ilks("gold");
        assertEq(dust, 0);
    }

    function testFail_setIlkMinVaultAmountGt() public {
        action.setIlkMaxLiquidationAmount_test("gold", 100);
        action.setIlkMinVaultAmount_test("gold", 101); // Fail here
    }

    function test_setIlkLiquidationPenalty() public {
        action.setIlkLiquidationPenalty_test("gold", 1325); // 13.25%
        (, uint256 chop,,) = dog.ilks("gold");
        assertEq(chop, 113.25 ether / 100);  // WAD pct 113.25%
    }

    function test_setIlkMaxLiquidationAmount() public {
        action.setIlkMaxLiquidationAmount_test("gold", 50 * THOUSAND);
        (,, uint256 hole,) = dog.ilks("gold");
        assertEq(hole, 50 * THOUSAND * RAD);
    }

    function test_setIlkLiquidationRatio() public {
        action.setIlkLiquidationRatio_test("gold", 15000); // 150% in bp
        (, uint256 mat) = spot.ilks("gold");
        assertEq(mat, ray(150 ether / 100)); // RAY pct
    }

    function test_setStartingPriceMultiplicativeFactor() public {
        action.setStartingPriceMultiplicativeFactor_test("gold", 15000); // 150%
        assertEq(ilks["gold"].clip.buf(), 150 * RAY / 100); // RAY pct
    }

    function test_setAuctionTimeBeforeReset() public {
        action.setAuctionTimeBeforeReset_test("gold", 12 hours);
        assertEq(ilks["gold"].clip.tail(), 12 hours);
    }

    function test_setAuctionPermittedDrop() public {
        action.setAuctionPermittedDrop_test("gold", 8000);
        assertEq(ilks["gold"].clip.cusp(), 80 * RAY / 100);
    }

    function test_setKeeperIncentivePercent() public {
        action.setKeeperIncentivePercent_test("gold", 10); // 0.1 %
        assertEq(ilks["gold"].clip.chip(), 10 * WAD / 10000);
    }

    function test_setKeeperIncentiveFlatRate() public {
        action.setKeeperIncentiveFlatRate_test("gold", 1000); // 1000 Dai
        assertEq(ilks["gold"].clip.tip(), 1000 * RAD);
    }

    function test_setLiquidationBreakerPriceTolerance() public {
        action.setLiquidationBreakerPriceTolerance_test(address(ilks["gold"].clip), 6000);
        assertEq(clipperMom.tolerance(address(ilks["gold"].clip)), 600000000000000000000000000);

    }

    function test_setIlkStabilityFee() public {
        hevm.warp(START_TIME + 1 days);
        action.setIlkStabilityFee_test("gold", 1000000001243680656318820312);
        (uint256 duty, uint256 rho) = jug.ilks("gold");
        assertEq(duty, 1000000001243680656318820312);
        assertEq(rho, START_TIME + 1 days);
    }

    /**************************/
    /*** Pricing Management ***/
    /**************************/

    function test_setLinearDecrease() public {
        LinearDecrease calc = new LinearDecrease();
        calc.rely(address(action));
        action.setLinearDecrease_test(address(calc), 14 hours);
        assertEq(calc.tau(), 14 hours);
    }

    function test_setStairstepExponentialDecrease() public {
        StairstepExponentialDecrease calc = new StairstepExponentialDecrease();
        calc.rely(address(action));
        action.setStairstepExponentialDecrease_test(address(calc), 90, 9999); // 90 seconds per step, 99.99% multiplicative
        assertEq(calc.step(), 90);
        assertEq(calc.cut(), 999900000000000000000000000);
    }

    function test_setExponentialDecrease() public {
        ExponentialDecrease calc = new ExponentialDecrease();
        calc.rely(address(action));
        action.setExponentialDecrease_test(address(calc), 9999); // 99.99% multiplicative
        assertEq(calc.cut(), 999900000000000000000000000);
    }


    /*************************/
    /*** Oracle Management ***/
    /*************************/

    function test_whitelistOracle_OSM() public {
        address tokenPip = address(new OSM(address(median)));

        assertEq(median.bud(tokenPip), 0);
        action.whitelistOracleMedians_test(tokenPip);
        assertEq(median.bud(tokenPip), 1);
    }

    function test_whitelistOracle_LP() public {
        // Mock an LP oracle and whitelist it
        address token0 = address(new DSToken("nil"));
        address token1 = address(new DSToken("one"));
        Median  med0   = new Median();
        Median  med1   = new Median();
        address lperc  = address(new UniPairMock(token0, token1));
        med0.rely(address(action));
        med1.rely(address(action));
        UNIV2LPOracle lorc = new UNIV2LPOracle(address(lperc), "NILONE", address(med0), address(med1));

        assertEq(med0.bud(address(lorc)), 0);
        assertEq(med1.bud(address(lorc)), 0);
        action.whitelistOracleMedians_test(address(lorc));
        assertEq(med0.bud(address(lorc)), 1);
        assertEq(med1.bud(address(lorc)), 1);
    }

    function test_whitelistOracleWithDSValue_LP() public {
        // Should not fail for LP tokens if one or more oracles are DSValue
        address token0 = address(new DSToken("nil"));
        address token1 = address(new DSToken("one"));
        DSValue med0   = new DSValue();
        DSValue med1   = new DSValue();
        address lperc  = address(new UniPairMock(token0, token1));
        med0.poke(bytes32(uint256(100)));
        med1.poke(bytes32(uint256(100)));
        UNIV2LPOracle lorc = new UNIV2LPOracle(address(lperc), "NILONE", address(med0), address(med1));

        action.whitelistOracleMedians_test(address(lorc));
    }

    function test_addReaderToWhitelistCall() public {
        address reader = address(1);

        assertEq(median.bud(address(1)), 0);
        action.addReaderToWhitelistCall_test(address(median), reader);
        assertEq(median.bud(address(1)), 1);
    }

    function test_removeReaderFromWhitelistCall() public {
        address reader = address(1);

        assertEq(median.bud(address(1)), 0);
        action.addReaderToWhitelistCall_test(address(median), reader);
        assertEq(median.bud(address(1)), 1);
        action.removeReaderFromWhitelistCall_test(address(median), reader);
        assertEq(median.bud(address(1)), 0);
    }

    function test_setMedianWritersQuorum() public {
        action.setMedianWritersQuorum_test(address(median), 11);
        assertEq(median.bar(), 11);
    }

    function test_addReaderToWhitelist() public {
        OSM osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
    }

    function test_removeReaderFromOSMWhitelist() public {
        OSM osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
        action.removeReaderFromWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 0);
    }

    function test_allowOSMFreeze() public {
        OSM osm = ilks["gold"].osm;
        action.allowOSMFreeze_test(address(osm), "gold");
        assertEq(osmMom.osms("gold"), address(osm));
    }

    /*****************************/
    /*** Direct Deposit Module ***/
    /*****************************/

    function test_setD3MTargetInterestRate() public {
        AaveMock aave = new AaveMock();
        DssDirectDepositAaveDai d3m = new DssDirectDepositAaveDai(address(clog), "tungsten", address(aave), address(0));
        d3m.rely(address(action));

        action.setD3MTargetInterestRate_test(address(d3m), 500); // set to 5%
        assertEq(d3m.bar(), 5 * RAY / 100);

        action.setD3MTargetInterestRate_test(address(d3m), 0);   // set to 0%
        assertEq(d3m.bar(), 0);

        action.setD3MTargetInterestRate_test(address(d3m), 9900); // set to 99%
        assertEq(d3m.bar(), 99 * RAY / 100);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function test_collateralOnboardingBase() public {
        string memory silk = "silver";
        bytes32 ilk = stringToBytes32(silk);

        DSToken token     = new DSToken(silk);
        GemJoin tokenJoin = new GemJoin(address(vat), ilk, address(token));
        Clipper tokenClip = new Clipper(address(vat), address(spot), address(dog), ilk);
        LinearDecrease tokenCalc = new LinearDecrease();
        tokenCalc.file("tau", 1);
        address tokenPip  = address(new DSValue());

        tokenPip = address(new OSM(address(tokenPip)));
        OSM(tokenPip).rely(address(action));
        tokenClip.rely(address(action));
        tokenJoin.rely(address(action));
        tokenClip.deny(address(this));
        tokenJoin.deny(address(this));

        action.addCollateralBase_test(ilk, address(token), address(tokenJoin), address(tokenClip), address(tokenCalc), tokenPip);

        assertEq(vat.wards(address(tokenJoin)), 1);
        assertEq(dog.wards(address(tokenClip)), 1);

        assertEq(tokenClip.wards(address(end)), 1);

        (,,uint256 _class, uint256 _dec, address _gem, address _pip, address _join, address _xlip) = reg.info(ilk);

        assertEq(_class, 1);
        assertEq(_dec, 18);
        assertEq(_gem, address(token));
        assertEq(_pip, address(tokenPip));
        assertEq(_join, address(tokenJoin));
        assertEq(_xlip, address(tokenClip));
        assertEq(address(tokenClip.calc()), address(tokenCalc));
    }

    function collateralOnboardingTest(bool liquidatable, bool isOsm, bool medianSrc) internal {

        string memory silk = "silver";
        bytes32 ilk = stringToBytes32(silk);

        address token     = address(new DSToken(silk));
        GemJoin tokenJoin = new GemJoin(address(vat), ilk, token);
        Clipper tokenClip = new Clipper(address(vat), address(spot), address(dog), ilk);
        LinearDecrease tokenCalc = new LinearDecrease();
        tokenCalc.file("tau", 1);
        address tokenPip  = address(new DSValue());

        if (isOsm) {
            tokenPip = medianSrc ? address(new OSM(address(median))) : address(new OSM(address(tokenPip)));
            OSM(tokenPip).rely(address(action));
        }

        tokenClip.rely(address(action));
        tokenJoin.rely(address(action));
        tokenClip.deny(address(this));
        tokenJoin.deny(address(this));

        {
            uint256 globalLine = vat.Line();

            action.addNewCollateral_test(
                CollateralOpts({
                    ilk:                   ilk,
                    gem:                   token,
                    join:                  address(tokenJoin),
                    clip:                  address(tokenClip),
                    calc:                  address(tokenCalc),
                    pip:                   tokenPip,
                    isLiquidatable:        liquidatable,
                    isOSM:                 isOsm,
                    whitelistOSM:          medianSrc,
                    ilkDebtCeiling:        100 * MILLION,
                    minVaultAmount:        100,
                    maxLiquidationAmount:  50 * THOUSAND,
                    liquidationPenalty:    1300,
                    ilkStabilityFee:       1000000001243680656318820312,
                    startingPriceFactor:   13000,
                    breakerTolerance:      6000,
                    auctionDuration:       6 hours,
                    permittedDrop:         4000,
                    liquidationRatio:      15000,
                    kprFlatReward:         100,
                    kprPctReward:          10
                })
            );

            assertEq(vat.Line(), globalLine + 100 * MILLION * RAD);
        }

        {
        assertEq(vat.wards(address(tokenJoin)), 1);
        assertEq(dog.wards(address(tokenClip)), 1);

        assertEq(tokenClip.wards(address(end)), 1);
        assertEq(tokenClip.wards(address(dog)), 1); // Use "stopped" instead of ward to disable.

        if (liquidatable) {
            assertEq(tokenClip.stopped(), 0);
            assertEq(tokenClip.wards(address(clipperMom)), 1);
        } else {
            assertEq(tokenClip.stopped(), 3);
            assertEq(tokenClip.wards(address(clipperMom)), 0);
        }
        }

        if (isOsm) {
          assertEq(OSM(tokenPip).wards(address(osmMom)),     1);
          assertEq(OSM(tokenPip).bud(address(spot)),         1);
          assertEq(OSM(tokenPip).bud(address(tokenClip)),    1);
          assertEq(OSM(tokenPip).bud(address(clipperMom)),   1);
          assertEq(OSM(tokenPip).bud(address(end)),          1);

          if (medianSrc) assertEq(median.bud(tokenPip),      1);
          assertEq(osmMom.osms(ilk), tokenPip);
        }

        {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            (, uint256 chop, uint256 hole, uint256 dirt) = dog.ilks(ilk);
            assertEq(line, 100 * MILLION * RAD);
            assertEq(dust, 100 * RAD);
            assertEq(hole, 50 * THOUSAND * RAD);
            assertEq(dirt, 0);
            assertEq(chop, 113 ether / 100);  // WAD pct 113%

            (uint256 duty, uint256 rho) = jug.ilks(ilk);
            assertEq(duty, 1000000001243680656318820312);
            assertEq(rho, START_TIME);
        }

        {
            assertEq(tokenClip.buf(), 130 * RAY / 100);
            assertEq(tokenClip.tail(), 6 hours);
            assertEq(tokenClip.cusp(), 40 * RAY / 100);

            assertEq(clipperMom.tolerance(address(tokenClip)), 6000 * RAY / 10000);

            assertEq(uint256(tokenClip.tip()), 100 * RAD);
            assertEq(uint256(tokenClip.chip()), 10 * WAD / 10000);

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
    function test_officeHoursCanOverrideInAction() public {
        DssTestNoOfficeHoursAction actionNoOfficeHours = new DssTestNoOfficeHoursAction();
        actionNoOfficeHours.execute();
        assertTrue(!actionNoOfficeHours.officeHours());
    }

    /***************/
    /*** Payment ***/
    /***************/

    function sendPaymentFromSurplusBuffer_test() public {
        address target = address(this);

        action.delegateVat_test(address(daiJoin));

        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(daiToken.balanceOf(target), 0);
        assertEq(vat.dai(address(vow)), 0);
        assertEq(vat.sin(address(vow)), 0);
        action.sendPaymentFromSurplusBuffer_test(target, 100);
        assertEq(vat.dai(target), 0);
        assertEq(vat.sin(target), 0);
        assertEq(daiToken.balanceOf(target), 100 * WAD);
        assertEq(vat.dai(address(vow)), 0);
        assertEq(vat.sin(address(vow)), 100 * RAD);
    }

    /************/
    /*** Misc ***/
    /************/

    function test_lerp_Line() public {
        LerpAbstract lerp = LerpAbstract(action.linearInterpolation_test("myLerp001", address(vat), "Line", block.timestamp, rad(2400 ether), rad(0 ether), 1 days));
        assertEq(lerp.what(), "Line");
        assertEq(lerp.start(), rad(2400 ether));
        assertEq(lerp.end(), rad(0 ether));
        assertEq(lerp.duration(), 1 days);
        assertTrue(!lerp.done());
        assertEq(lerp.startTime(), block.timestamp);
        assertEq(vat.Line(), rad(2400 ether));
        hevm.warp(now + 1 hours);
        assertEq(vat.Line(), rad(2400 ether));
        lerp.tick();
        assertEq(vat.Line(), rad(2300 ether + 1600));   // Small amount at the end is rounding errors
        hevm.warp(now + 1 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(2200 ether + 800));
        hevm.warp(now + 6 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(1600 ether + 800));
        hevm.warp(now + 1 days);
        assertEq(vat.Line(), rad(1600 ether + 800));
        lerp.tick();
        assertEq(vat.Line(), rad(0 ether));
        assertTrue(lerp.done());
        assertEq(vat.wards(address(lerp)), 0);
    }

    function test_lerp_ilk_line() public {
        bytes32 ilk = "gold";
        LerpAbstract lerp = LerpAbstract(action.linearInterpolation_test("myLerp001", address(vat), ilk, "line", block.timestamp, rad(2400 ether), rad(0 ether), 1 days));
        lerp.tick();
        assertEq(lerp.what(), "line");
        assertEq(lerp.start(), rad(2400 ether));
        assertEq(lerp.end(), rad(0 ether));
        assertEq(lerp.duration(), 1 days);
        assertTrue(!lerp.done());
        (,,, uint line,) = vat.ilks(ilk);
        assertEq(lerp.startTime(), block.timestamp);
        assertEq(line, rad(2400 ether));
        hevm.warp(now + 1 hours);
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2400 ether));
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2300 ether + 1600));   // Small amount at the end is rounding errors
        hevm.warp(now + 1 hours);
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2200 ether + 800));
        hevm.warp(now + 6 hours);
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        hevm.warp(now + 1 days);
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(0 ether));
        assertTrue(lerp.done());
        assertEq(vat.wards(address(lerp)), 0);
    }
}

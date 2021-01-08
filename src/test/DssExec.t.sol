// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssExec.t.sol -- MakerDAO Executive Spellcrafting Library Tests
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
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-math/math.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import "dss-interfaces/Interfaces.sol";

import "../DssExec.sol";
import "../DssAction.sol";
import "../CollateralOpts.sol";
import {DssExecLib} from "../DssExecLib.sol";
import "./rates.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract DssLibSpellAction is DssAction { // This could be changed to a library if the lib is hardcoded and the constructor removed

    // This can be hardcoded away later or can use the chain-log
    constructor(address lib, bool ofcHrs) DssAction(lib, ofcHrs) public {}

    uint256 constant MILLION  = 10 ** 6;

    function execute() external override {
        CollateralOpts memory XMPL_A = CollateralOpts({
            ilk:                   "XMPL-A",
            gem:                   0xCE4F3774620764Ea881a8F8840Cbe0F701372283,
            join:                  0xa30925910067a2d9eB2a7358c017E6075F660842,
            flip:                  0x32c6DF17f8E94694977aa41A595d8dc583836A51,
            pip:                   0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a, // Using LRC-A pip as a dummy
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        100,
            maxLiquidationAmount:  50000,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000705562181084137268,
            bidIncrease:           300,
            bidDuration:           6 hours,
            auctionDuration:       6 hours,
            liquidationRatio:      15000
        });
        addNewCollateral(XMPL_A);

        setIlkDebtCeiling("ETH-A", 10 * MILLION);
        setGlobalDebtCeiling(1500 * MILLION);
    }
}

contract DssLibExecTest is DSTest, DSMath {

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 chop;
        uint256 dunk;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
        uint256 liquidations;
    }

    struct SystemValues {
        uint256 dsr_rate;
        uint256 vat_Line;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 cat_box;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    event Debug(uint256);

    // MAINNET ADDRESSES
    PauseAbstract        pause = PauseAbstract(      0xbE286431454714F511008713973d3B053A2d38f3);
    address         pauseProxy =                     0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief = DSChiefAbstract(    0x0a3f6849f78076aefaDf113F5BED87720274dDC0);
    VatAbstract            vat = VatAbstract(        0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract            vow = VowAbstract(        0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    CatAbstract            cat = CatAbstract(        0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea);
    PotAbstract            pot = PotAbstract(        0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract            jug = JugAbstract(        0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract          spot = SpotAbstract(       0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    DSTokenAbstract        gov = DSTokenAbstract(    0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    EndAbstract            end = EndAbstract(        0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    IlkRegistryAbstract    reg = IlkRegistryAbstract(0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24);

    OsmMomAbstract      osmMom = OsmMomAbstract(     0x76416A4d5190d071bfed309861527431304aA14f);
    FlipperMomAbstract flipMom = FlipperMomAbstract( 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472);

    // XMPL-A specific
    GemAbstract           xmpl = GemAbstract(        0xCE4F3774620764Ea881a8F8840Cbe0F701372283);
    GemJoinAbstract  joinXMPLA = GemJoinAbstract(    0xa30925910067a2d9eB2a7358c017E6075F660842);
    OsmAbstract         pipXMPL = OsmAbstract(       0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a);
    FlipAbstract     flipXMPLA = FlipAbstract(       0x32c6DF17f8E94694977aa41A595d8dc583836A51);
    MedianAbstract    medXMPLA = MedianAbstract(     0xcCe92282d9fe310F4c232b0DA9926d5F24611C7B);

    ChainlogAbstract chainlog  = ChainlogAbstract(   0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address    makerDeployer05 = 0xDa0FaB05039809e63C5D068c897c3e602fA97457;

    SystemValues afterSpell;

    Hevm hevm;

    Rates rates;

    DssExec spell;
    address execlib;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant HUNDRED  = 10 ** 2;
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant BILLION  = 10 ** 9;
    uint256 constant RAD      = 10 ** 45;

    // not provided in DSMath
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
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
    // 10^-5 (tenth of a basis point) as a RAY
    uint256 TOLERANCE = 10 ** 22;

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 * 60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (10000 + percentValue) * (10 ** 23);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        rates = new Rates();

        execlib = address(new DssExecLib()); // This would be deployed only once

        spell = new DssExec(
            "A test dss exec spell",                    // Description
            now + 30 days,                              // Expiration
            address(new DssLibSpellAction(execlib, true))
        );

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            dsr_rate:     0,               // In basis points
            vat_Line:     1500 * MILLION,  // In whole Dai units
            pause_delay:  pause.delay(),   // In seconds
            vow_wait:     vow.wait(),      // In seconds
            vow_dump:     vow.dump()/WAD,  // In whole Dai units
            vow_sump:     vow.sump()/RAD,  // In whole Dai units
            vow_bump:     vow.bump()/RAD,  // In whole Dai units
            vow_hump:     vow.hump()/RAD,  // In whole Dai units
            cat_box:      cat.box()/RAD,   // In whole Dai units
            ilk_count:    reg.count() + 1  // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        (,,,, uint256 _dust) = vat.ilks("ETH-A");
        (,, uint256 _dunk) = cat.ilks("ETH-A");
        (uint256 _duty,)  = jug.ilks("ETH-A");
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            line:         10 * MILLION,    // In whole Dai units
            dust:         _dust/RAD,        // In whole Dai units
            pct:          _duty,             // In basis points
            chop:         1300,            // In basis points
            dunk:         _dunk/RAD,        // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          6 hours,         // In seconds
            tau:          6 hours,         // In seconds
            liquidations: 1                // 1 if enabled
        });
        // New collateral
        afterSpell.collaterals["XMPL-A"] = CollateralValues({
            line:         3 * MILLION,     // In whole Dai units
            dust:         500,             // In whole Dai units
            pct:          225,             // In basis points
            chop:         1300,            // In basis points
            dunk:         50 * THOUSAND,   // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          6 hours,         // In seconds
            tau:          6 hours,         // In seconds
            liquidations: 1                // 1 if enabled
        });
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = now + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCast() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if(day >= 5) {
            castTime += 7 days - day * 86400;
        }

        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 21) {
            castTime += 24 hours - hour * 3600 + 14 hours;
        } else if (hour < 14) {
            castTime += 14 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        uint expectedDSRRate = rates.rates(values.dsr_rate);
        // make sure dsr is less than 100% APR
        // bc -l <<< 'scale=27; e( l(2.00)/(60 * 60 * 24 * 365) )'
        // 1000000021979553151239153027
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027
        );
        assertTrue(diffCalc(expectedRate(values.dsr_rate), yearlyYield(expectedDSRRate)) <= TOLERANCE);

        {
        // Line values in RAD
        uint normalizedLine = values.vat_Line * RAD;
        assertEq(vat.Line(), normalizedLine);
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < 100 * BILLION * RAD) ||
            vat.Line() == 0
        );
        }

        // Pause delay
        assertEq(pause.delay(), values.pause_delay);

        // wait
        assertEq(vow.wait(), values.vow_wait);

        {
        // dump values in WAD
        uint normalizedDump = values.vow_dump * WAD;
        assertEq(vow.dump(), normalizedDump);
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0
        );
        }
        {
        // sump values in RAD
        uint normalizedSump = values.vow_sump * RAD;
        assertEq(vow.sump(), normalizedSump);
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0
        );
        }
        {
        // bump values in RAD
        uint normalizedBump = values.vow_bump * RAD;
        assertEq(vow.bump(), normalizedBump);
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0
        );
        }
        {
        // hump values in RAD
        uint normalizedHump = values.vow_hump * RAD;
        assertEq(vow.hump(), normalizedHump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0
        );
        }

        // box values in RAD
        {
            uint normalizedBox = values.cat_box * RAD;
            assertEq(cat.box(), normalizedBox);
        }

        // check number of ilks
        assertEq(reg.count(), values.ilk_count);
    }

    function checkCollateralValues(bytes32 ilk, SystemValues storage values) internal {
        (uint duty,)  = jug.ilks(ilk);

        uint256 normRate;
        if (values.collaterals[ilk].pct > WAD) {
            // Actual rate assigned
            normRate = values.collaterals[ilk].pct;
        } else {
            // basis points used
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND);   // check value lt 1000%
            normRate = rates.rates(values.collaterals[ilk].pct);
            assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE);
        }

        // make sure duty is less than 1000% APR
        // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
        // 1000000073014496989316680335
        assertTrue(duty >= RAY && duty < 1000000073014496989316680335);  // gt 0 and lt 1000%
        {
        (,,, uint line, uint dust) = vat.ilks(ilk);
        // Convert whole Dai units to expected RAD
        uint normalizedTestLine = values.collaterals[ilk].line * RAD;
        assertEq(line, normalizedTestLine);
        assertTrue((line >= RAD && line < BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
        uint normalizedTestDust = values.collaterals[ilk].dust * RAD;
        assertEq(dust, normalizedTestDust);
        assertTrue((dust >= RAD && dust < 10 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 10k
        }
        {
        (, uint chop, uint dunk) = cat.ilks(ilk);
        // Convert BP to system expected value
        uint normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
        assertEq(chop, normalizedTestChop);
        // make sure chop is less than 100%
        assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%
        // Convert whole Dai units to expected RAD
        uint normalizedTestDunk = values.collaterals[ilk].dunk * RAD;
        assertEq(dunk, normalizedTestDunk);
        // put back in after LIQ-1.2
        assertTrue(dunk >= RAD && dunk < MILLION * RAD);
        }
        {
        (,uint mat) = spot.ilks(ilk);
        // Convert BP to system expected value
        uint normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
        assertEq(mat, normalizedTestMat);
        assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%
        }
        {
        (address flipper,,) = cat.ilks(ilk);
        FlipAbstract flip = FlipAbstract(flipper);
        // Convert BP to system expected value
        uint normalizedTestBeg = (values.collaterals[ilk].beg + 10000)  * 10**14;
        assertEq(uint(flip.beg()), normalizedTestBeg);
        assertTrue(flip.beg() >= WAD && flip.beg() < 105 * WAD / 100);  // gt eq 0% and lt 5%
        assertEq(uint(flip.ttl()), values.collaterals[ilk].ttl);
        assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours);         // gt eq 10 minutes and lt 10 hours
        assertEq(uint(flip.tau()), values.collaterals[ilk].tau);
        assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days);          // gt eq 10 minutes and lt eq 3 days

        assertEq(flip.wards(address(cat)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
        assertEq(flip.wards(address(makerDeployer05)), 0); // Check deployer denied
        assertEq(flip.wards(address(pauseProxy)), 1); // Check pause_proxy ward
        }
        {
        GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
        assertEq(join.wards(address(makerDeployer05)), 0); // Check deployer denied
        assertEq(join.wards(address(pauseProxy)), 1); // Check pause_proxy ward
        }
    }

    function testSpellIsCast_mainnet() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);
        checkCollateralValues("ETH-A",  afterSpell);

        assertTrue(spell.officeHours());
        assertTrue(spell.action() != address(0));
    }

    event Debug(uint, uint);

    function testSpellIsCast_XMPL_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        pipXMPL.poke();
        hevm.warp(now + 3601);
        pipXMPL.poke();
        spot.poke("XMPL-A");

        hevm.store(
            address(xmpl),
            keccak256(abi.encode(address(this), uint256(3))),
            bytes32(uint256(10 * THOUSAND * WAD))
        );

        // Check median matches pip.src()
        assertEq(pipXMPL.src(), address(medXMPLA));

        // Authorization
        assertEq(joinXMPLA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinXMPLA)), 1);
        assertEq(cat.wards(address(flipXMPLA)), 1);
        assertEq(flipXMPLA.wards(address(cat)), 1);
        assertEq(flipXMPLA.wards(pauseProxy), 1);
        assertEq(flipXMPLA.wards(address(end)), 1);
        assertEq(flipXMPLA.wards(address(flipMom)), 1);
        assertEq(pipXMPL.wards(address(osmMom)), 1);
        assertEq(pipXMPL.bud(address(spot)), 1);
        assertEq(pipXMPL.bud(address(end)), 1);
        assertEq(MedianAbstract(pipXMPL.src()).bud(address(pipXMPL)), 1);

        // Join to adapter
        assertEq(xmpl.balanceOf(address(this)), 10 * THOUSAND * WAD);
        assertEq(vat.gem("XMPL-A", address(this)), 0);
        xmpl.approve(address(joinXMPLA), 10 * THOUSAND * WAD);
        joinXMPLA.join(address(this), 10 * THOUSAND * WAD);
        assertEq(xmpl.balanceOf(address(this)), 0);
        assertEq(vat.gem("XMPL-A", address(this)), 10 * THOUSAND * WAD);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("XMPL-A", address(this), address(this), address(this), int(10 * THOUSAND * WAD), int(100 * WAD));
        assertEq(vat.gem("XMPL-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 100 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("XMPL-A", address(this), address(this), address(this), -int(10 * THOUSAND * WAD), -int(100 * WAD));
        assertEq(vat.gem("XMPL-A", address(this)), 10 * THOUSAND * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        joinXMPLA.exit(address(this), 10 * THOUSAND * WAD);
        assertEq(xmpl.balanceOf(address(this)), 10 * THOUSAND * WAD);
        assertEq(vat.gem("XMPL-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        xmpl.approve(address(joinXMPLA), 10 * THOUSAND * WAD);
        joinXMPLA.join(address(this), 10 * THOUSAND * WAD);
        (,,uint256 spotV,,) = vat.ilks("XMPL-A");
        // dart max amount of DAI
        vat.frob("XMPL-A", address(this), address(this), address(this), int(10 * THOUSAND * WAD), int(mul(10 * THOUSAND * WAD, spotV) / RAY));
        hevm.warp(now + 1);
        jug.drip("XMPL-A");
        assertEq(flipXMPLA.kicks(), 0);
        cat.bite("XMPL-A", address(this));
        assertEq(flipXMPLA.kicks(), 1);
    }

    function testExecLibDeployCost() public {
        new DssExecLib();
    }

    function testExecDeployCost() public {
        new DssExec(
            "Basic Spell",                              // Description
            now + 30 days,                              // Expiration
            address(new DssLibSpellAction(execlib, true))
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssExec.t.sol -- MakerDAO Executive Spellcrafting Library Tests
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

pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "dss-interfaces/Interfaces.sol";

import "../DssExec.sol";
import "../DssAction.sol";
import "../CollateralOpts.sol";
import "./rates.sol";

interface SpellLike {
    function done() external view returns (bool);
    function cast() external;
    function nextCastTime() external returns (uint256);
}

interface ClipFabLike {
    function newClip(address owner, address vat, address spotter, address dog, bytes32 ilk) external returns (address clip);
}

interface GemJoinFabLike {
    function newGemJoin(address owner, bytes32 ilk, address gem) external returns (address join);
}

interface CalcFabLike {
    function newLinearDecrease(address owner) external returns (address calc);
}

contract DssLibSpellAction is DssAction { // This could be changed to a library if the lib is hardcoded and the constructor removed

    ChainlogAbstract constant public LOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function description() external override pure returns (string memory) {
        return "DssLibSpellAction Description";
    }

    uint256 constant MILLION  = 10 ** 6;

    function actions() public override {

        // Basic cob setup
        DSTokenAbstract xmpl_gem  = DSTokenAbstract(0xCE4F3774620764Ea881a8F8840Cbe0F701372283);
        ClipAbstract xmpl_clip = ClipAbstract(ClipFabLike(LOG.getAddress("CLIP_FAB")).newClip(DssExecLib.pauseProxy(), DssExecLib.vat(), DssExecLib.spotter(), DssExecLib.dog(), "XMPL-A"));
        GemJoinAbstract xmpl_join = GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), "XMPL-A", address(xmpl_gem)));
        xmpl_clip.rely(DssExecLib.pauseProxy());
        xmpl_join.rely(DssExecLib.pauseProxy());
        address xmpl_pip = 0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C; // Using USDT pip as a dummy

        LinearDecreaseAbstract xmpl_calc = LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        DssExecLib.setLinearDecrease(address(xmpl_calc), 1);

        CollateralOpts memory XMPL_A = CollateralOpts({
            ilk:                   "XMPL-A",
            gem:                   address(xmpl_gem),
            join:                  address(xmpl_join),
            clip:                  address(xmpl_clip),
            calc:                  address(xmpl_calc),
            pip:                   xmpl_pip,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        2000,
            maxLiquidationAmount:  50000,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000705562181084137268,
            startingPriceFactor:   13000,
            breakerTolerance:      7000,   // Allows for a 30% hourly price drop before disabling liquidations
            auctionDuration:       10 hours,
            permittedDrop:         4000,
            liquidationRatio:      15000,
            kprFlatReward:         5,      // 5 Dai
            kprPctReward:          5       // 0.05%
        });

        DssExecLib.addNewCollateral(XMPL_A);

        DssExecLib.setIlkDebtCeiling("LINK-A", 10 * MILLION);
        DssExecLib.setIlkMinVaultAmount("LINK-A", 800);
        DssExecLib.setIlkLiquidationRatio("LINK-A", 16000);
        DssExecLib.setIlkLiquidationPenalty("LINK-A", 1400);
        DssExecLib.setIlkMaxLiquidationAmount("LINK-A", 100000);
        DssExecLib.setAuctionTimeBeforeReset("LINK-A", 2 hours);
        DssExecLib.setKeeperIncentivePercent("LINK-A", 2); // 0.02% keeper incentive
        DssExecLib.setGlobalDebtCeiling(10000 * MILLION);

    }
}

contract DssLibExecTest is Test {

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 chop;
        uint256 hole;
        uint256 buf;
        uint256 tail;
        uint256 cusp;
        uint256 chip;
        uint256 tip;
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
        uint256 dog_Hole;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    event Debug(uint256);

    ChainlogAbstract constant public LOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // MAINNET ADDRESSES
    PauseAbstract        pause = PauseAbstract(      LOG.getAddress("MCD_PAUSE"));
    address         pauseProxy =                     LOG.getAddress("MCD_PAUSE_PROXY");
    DSChiefAbstract      chief = DSChiefAbstract(    LOG.getAddress("MCD_ADM"));
    VatAbstract            vat = VatAbstract(        LOG.getAddress("MCD_VAT"));
    VowAbstract            vow = VowAbstract(        LOG.getAddress("MCD_VOW"));
    CatAbstract            cat = CatAbstract(        LOG.getAddress("MCD_CAT"));
    DogAbstract            dog = DogAbstract(        LOG.getAddress("MCD_DOG"));
    PotAbstract            pot = PotAbstract(        LOG.getAddress("MCD_POT"));
    JugAbstract            jug = JugAbstract(        LOG.getAddress("MCD_JUG"));
    SpotAbstract          spot = SpotAbstract(       LOG.getAddress("MCD_SPOT"));

    DSTokenAbstract        gov = DSTokenAbstract(    LOG.getAddress("MCD_GOV"));
    EndAbstract            end = EndAbstract(        LOG.getAddress("MCD_END"));
    IlkRegistryAbstract    reg = IlkRegistryAbstract(LOG.getAddress("ILK_REGISTRY"));

    OsmMomAbstract      osmMom = OsmMomAbstract(     LOG.getAddress("OSM_MOM"));
    ClipperMomAbstract clipMom = ClipperMomAbstract( LOG.getAddress("CLIPPER_MOM"));

    // XMPL-A specific
    GemAbstract           xmpl = GemAbstract(        0xCE4F3774620764Ea881a8F8840Cbe0F701372283);
    GemJoinAbstract  joinXMPLA;
    OsmAbstract        pipXMPL = OsmAbstract(        LOG.getAddress("PIP_USDT"));
    ClipAbstract     clipXMPLA;

    SystemValues afterSpell;

    Rates rates;

    DssExec spell;

    uint256 constant HUNDRED  = 10 ** 2;
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant BILLION  = 10 ** 9;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // not provided in DSMath
    function _rpow(uint x, uint n, uint b) internal pure returns (uint z) {
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
        return _rpow(duty, (365 * 24 * 60 * 60), RAY);
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
        rates = new Rates();

        spell = new DssExec(
            block.timestamp + 30 days,                  // Expiration
            address(new DssLibSpellAction())
        );

        //
        // Test for all system configuration changes
        //
        afterSpell.dsr_rate     =  0;               // In basis points
        afterSpell.vat_Line     =  10000 * MILLION; // In whole Dai units
        afterSpell.pause_delay  =  pause.delay();   // In seconds
        afterSpell.vow_wait     =  vow.wait();      // In seconds
        afterSpell.vow_dump     =  vow.dump()/WAD;  // In whole Dai units
        afterSpell.vow_sump     =  vow.sump()/RAD;  // In whole Dai units
        afterSpell.vow_bump     =  vow.bump()/RAD;  // In whole Dai units
        afterSpell.vow_hump     =  vow.hump()/RAD;  // In whole Dai units
        afterSpell.dog_Hole     =  dog.Hole()/RAD;  // In whole Dai units
        afterSpell.ilk_count    =  reg.count() + 1; // Num expected in system

        //
        // Test for all collateral based changes here
        //
        (uint256 _duty,)  = jug.ilks("LINK-A");
        (address _clip,,,) = dog.ilks("LINK-A");
        ClipAbstract clip = ClipAbstract(_clip);
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            line:          10 * MILLION,         // In whole Dai units
            dust:          800,                  // In whole Dai units
            pct:           _duty,                // In basis points
            buf:           clip.buf()*10000/RAY, // In basis points
            cusp:          clip.cusp()*10000/RAY,// In basis points
            chop:          1400,                 // In basis points
            tip:           clip.tip()/RAD,       // In whole Dai units
            chip:          2,                    // In basis points
            hole:          100000,               // In whole Dai units
            mat:           16000,                // In basis points
            beg:           400,                  // In basis points
            tail:          2 hours,              // In seconds
            ttl:           3 hours,              // In seconds
            tau:           3 hours,              // In seconds
            liquidations:  1                     // 1 if enabled
        });
        // New collateral
        afterSpell.collaterals["XMPL-A"] = CollateralValues({
            line:          3 * MILLION,          // In whole Dai units
            dust:          2000,                 // In whole Dai units
            pct:           225,                  // In basis points
            buf:           13000,                // In basis points
            cusp:          4000,                 // In basis points
            chop:          1300,                 // In basis points
            tip:           5,                    // In whole Dai units
            chip:          5,                    // In basis points
            hole:          50 * THOUSAND,        // In whole Dai units
            mat:           15000,                // In basis points
            beg:           300,                  // In basis points
            tail:          10 hours,             // In seconds
            ttl:           6 hours,              // In seconds
            tau:           6 hours,              // In seconds
            liquidations:  1                     // 1 if enabled
        });
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            vm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), type(uint256).max);
            chief.lock(gov.balanceOf(address(this)) - 1 ether);

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

        uint256 castTime = block.timestamp + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        vm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        vm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        vm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCast() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
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

        vm.warp(spell.nextCastTime());
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
        assertEq(vow.hump()/RAD, values.vow_hump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < THOUSAND * MILLION * RAD) ||
            vow.hump() == 0,
            "DssExec.t.sol/hump-sanity-check-fail"
        );
        }

        // Hole values in RAD
        {
            uint normalizedHole = values.dog_Hole * RAD;
            assertEq(dog.Hole(), normalizedHole);
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
        assertTrue((dust >= RAD && dust < 100 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 10k
        }
        {
        (, uint chop, uint hole, uint dirt) = dog.ilks(ilk);
        (,,,, uint dust) = vat.ilks(ilk);

        assertEq(hole, values.collaterals[ilk].hole * RAD);
        assertTrue(dirt <= hole + dust);

        // Convert BP to system expected value
        uint normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
        assertEq(chop, normalizedTestChop);
        // make sure chop is less than 100%
        assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%
        // Convert whole Dai units to expected RAD
        uint normalizedTestHole = values.collaterals[ilk].hole * RAD;
        assertEq(hole, normalizedTestHole);
        assertTrue(hole >= RAD && hole < MILLION * RAD);
        }
        {
        (,uint mat) = spot.ilks(ilk);
        // Convert BP to system expected value
        uint normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
        assertEq(mat, normalizedTestMat);
        assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%
        }
        {
        uint256 class = reg.class(ilk);
        if (class == 1) {
            (address clipper,,,) = dog.ilks(ilk);
            ClipAbstract clip = ClipAbstract(clipper);

            assertEq(clip.ilk(), ilk);
            assertEq(address(clip.vat()), address(vat));

            // buf [RAY]
            uint256 normalizedTestBuf = (values.collaterals[ilk].buf * RAY / 10000);
            assertEq(clip.buf(), normalizedTestBuf);
            // tail [seconds]
            assertEq(clip.tail(), values.collaterals[ilk].tail);
            // cusp
            uint256 normalizedTestCusp = (values.collaterals[ilk].cusp * RAY / 10000);
            assertEq(clip.cusp(), normalizedTestCusp);
            // chip
            assertEq(clip.chip(), values.collaterals[ilk].chip * WAD / 10000);
            // tip
            assertEq(clip.tip(), values.collaterals[ilk].tip * RAD);

            assertEq(clip.wards(address(dog)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
            assertEq(clip.wards(address(pauseProxy)), 1); // Check pause_proxy ward
        } else if (class == 2) {
            revert(); // Old stuff. Not used here.
        }

        }
        {
        GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
        assertEq(join.wards(address(pauseProxy)), 1); // Check pause_proxy ward
        }
    }

    function test_spellIsCastMainnet() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);
        checkCollateralValues("LINK-A",  afterSpell);
        checkCollateralValues("XMPL-A",  afterSpell);

        assertTrue(spell.officeHours());
        assertTrue(spell.action() != address(0));
    }

    function test_spellIsCastXMPLIntegration() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        pipXMPL.poke();
        vm.warp(block.timestamp + 3601);
        pipXMPL.poke();
        spot.poke("XMPL-A");

        vm.store(
            address(xmpl),
            keccak256(abi.encode(address(this), uint256(3))),
            bytes32(uint256(10 * THOUSAND * WAD))
        );

        (address clip,,,) = dog.ilks("XMPL-A");
        clipXMPLA = ClipAbstract(clip);
        joinXMPLA = GemJoinAbstract(reg.join("XMPL-A"));

        // Authorization
        assertEq(joinXMPLA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinXMPLA)), 1);
        assertEq(dog.wards(address(clipXMPLA)), 1);
        assertEq(clipXMPLA.wards(address(dog)), 1);
        assertEq(clipXMPLA.wards(pauseProxy), 1);
        assertEq(clipXMPLA.wards(address(end)), 1);
        assertEq(clipXMPLA.wards(address(clipMom)), 1);
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
        vat.frob("XMPL-A", address(this), address(this), address(this), int(10 * THOUSAND * WAD), int(2500 * WAD));
        assertEq(vat.gem("XMPL-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 2500 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("XMPL-A", address(this), address(this), address(this), -int(10 * THOUSAND * WAD), -int(2500 * WAD));
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
        vat.frob("XMPL-A", address(this), address(this), address(this), int(10 * THOUSAND * WAD), int(10 * THOUSAND * WAD * spotV / RAY));
        vm.warp(block.timestamp + 1);
        jug.drip("XMPL-A");
        assertEq(clipXMPLA.kicks(), 0);
        dog.bark("XMPL-A", address(this), address(this));
        assertEq(clipXMPLA.kicks(), 1);
    }
}

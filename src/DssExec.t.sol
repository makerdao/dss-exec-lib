pragma solidity ^0.6.7;

import "ds-test/test.sol";

import {Vat}     from 'dss/vat.sol';
import {End}     from 'dss/end.sol';
import {Vow}     from 'dss/vow.sol';
import {Cat}     from 'dss/cat.sol';
import {Spotter} from 'dss/spot.sol';
import {PipLike} from 'dss/spot.sol';
import {Flipper} from 'dss/flip.sol';
import {Flapper} from 'dss/flap.sol';
import {Flopper} from 'dss/flop.sol';
import {GemJoin} from 'dss/join.sol';

import "./DssExec.sol";
import "./DssExecLib.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract DssSpellActionTest {
    using DssExecLib for *;

    // Add spell actions here
    // ex.
    //   setGlobalLine(1200 * MILLION);
    //   setStabilityFee("ETH-A", 1000000001243680656318820312);
}

contract DssSpellTest is DssExec(
    "A test dss exec spell",                    // Description
    now + 30 days,                              // Expiration
    true,                                       // OfficeHours enabled
    address(new DssSpellActionTest())) {}       // Use the action above


// Tests

contract DssLibExecTest is DSTest {
    Hevm hevm;

    DssSpellTest dssTest;

    Vat vat;
    End end;
    Vow vow;
    Cat cat;
    Spotter spot;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }

    function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function initCollateral(bytes32 name) internal {
        DSToken coin = new DSToken(name);
        coin.setName(name);
        coin.mint(20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        dssTest = new DssSpellTest();

        vat  = new Vat();
        cat  = new Cat(address(vat));
        spot = new Spotter(address(vat));

        vat.rely(address(cat));
        vat.rely(address(spot));

        end = new End();
        end.file("vat",  address(vat));
        end.file("cat",  address(cat));
        end.file("spot", address(spot));

        initCollateral("ETH-A");
        initCollateral("BAT-A");
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}

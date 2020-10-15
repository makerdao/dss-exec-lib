pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import "dss-chain-log/ChainLog.sol";
// import "osm-mom/OsmMom.sol";
// import "mkr-authority/MkrAuthority.sol";
import "ilk-registry/IlkRegistry.sol";

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

interface Hevm {
    function warp(uint256) external;
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
    // OsmMom       osmMom;
    // MkrAuthority govGuard;

    Spotter spot;

    ChainLog log;

    struct Ilk {
        DSValue pip;
        DSToken gem;
        GemJoin gemA;
        Flipper flip;
    }

    mapping (bytes32 => Ilk) ilks;

    Flapper flap;
    Flopper flop;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant MLN = 10 ** 6;

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
        hevm.warp(604411200);

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

        jug      = new Jug(address(vat));
        reg      = new IlkRegistry(address(vat), address(cat), address(spot));
        // osmMom   = new OsmMom();
        // govGuard = new MkrAuthority();

        log = new ChainLog();

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
        // log.setAddress("OSM_MOM",     address(osmMom));
        // log.setAddress("GOV_GUARD",   address(govGuard));
        log.setAddress("FLIPPER_MOM", address(vat));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity_mainnet() public {
        assertTrue(true);
    }

    function test_chainlog() public {
        address vatTest = log.getAddress("MCD_VAT");
        assertEq(address(vat), vatTest);
    }
}

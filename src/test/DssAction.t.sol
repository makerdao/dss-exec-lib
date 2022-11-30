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

import "forge-std/Test.sol";
import "dss-interfaces/Interfaces.sol";

import "../CollateralOpts.sol";
import {DssTestAction, DssTestNoOfficeHoursAction}    from './DssTestAction.sol';

interface ChainlogLike is ChainlogAbstract {
    function sha256sum() external view returns (string calldata);
}

interface PipLike {
    function peek() external returns (bytes32, bool);
    function read() external returns (bytes32);
}

interface ClipFabLike {
    function newClip(address owner, address vat, address spotter, address dog, bytes32 ilk) external returns (address clip);
}

interface GemJoinFabLike {
    function newAuthGemJoin(address owner, bytes32 ilk, address gem) external returns (address join);
    function newGemJoin(address owner, bytes32 ilk, address gem) external returns (address join);
}

interface CalcFabLike {
    function newExponentialDecrease(address owner) external returns (address calc);
    function newLinearDecrease(address owner) external returns (address calc);
    function newStairstepExponentialDecrease(address owner) external returns (address calc);
}

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string calldata, address, uint48, uint48);
    function rely(address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaTokenFactoryLike {
    function createRwaToken(string calldata, string calldata, address) external returns (address token);
}

interface Univ2OracleFactoryLike {
    function build(address, address, bytes32, address, address) external returns (address oracle);
}

interface D3MLike {
    function bar() external view returns (uint256);
    function rely(address) external;
}

contract MockUniPair {
    address public token0; address public token1;
    constructor(address _token0, address _token1) public {
        token0 = _token0;  token1 = _token1;
    }
}

contract MockToken {
    uint256                                           public  totalSupply;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint256)) public  allowance;
    string                                            public  symbol;
    uint8                                             public  decimals = 18; // standard token precision. override to customize
    string                                            public  name = "";     // Optional token name


    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    constructor(string memory symbol_) public {
        symbol = symbol_;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = _sub(allowance[src][msg.sender], wad);
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = _sub(balanceOf[src], wad);
        balanceOf[dst] = _add(balanceOf[dst], wad);

        return true;
    }
    function mint(address guy, uint wad) public {
        balanceOf[guy] = _add(balanceOf[guy], wad);
        totalSupply = _add(totalSupply, wad);
    }

    function burn(address guy, uint wad) public {
        if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = _sub(allowance[guy][msg.sender], wad);
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = _sub(balanceOf[guy], wad);
        totalSupply = _sub(totalSupply, wad);
    }
}

contract MockValue {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() public view returns (bytes32) {
        bytes32 wut; bool haz;
        (wut, haz) = peek();
        require(haz, "haz-not");
        return wut;
    }
    function poke(bytes32 wut) public {
        val = wut;
        has = true;
    }
    function void() public {
        has = false;
    }
}

contract MockMedian {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Median/not-authorized");
        _;
    }

    uint128        val;
    uint32  public age;
    bytes32 public constant wat = "ethusd"; // You want to change this every deploy
    uint256 public bar = 1;

    // Authorized oracles, set by an auth
    mapping (address => uint256) public orcl;

    // Whitelisted contracts, set by an auth
    mapping (address => uint256) public bud;

    // Mapping for at most 256 oracles
    mapping (uint8 => address) public slot;

    modifier toll { require(bud[msg.sender] == 1, "Median/contract-not-whitelisted"); _;}

    event LogMedianPrice(uint256 val, uint256 age);

    //Set type of Oracle
    constructor() public {
        wards[msg.sender] = 1;
    }

    function read() external view toll returns (uint256) {
        require(val > 0, "Median/invalid-price-feed");
        return val;
    }

    function peek() external view toll returns (uint256,bool) {
        return (val, val > 0);
    }

    function recover(uint256 val_, uint256 age_, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(val_, age_, wat)))),
            v, r, s
        );
    }

    function poke(
        uint256[] calldata val_, uint256[] calldata age_,
        uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external
    {
        require(val_.length == bar, "Median/bar-too-low");

        uint256 bloom = 0;
        uint256 last = 0;
        uint256 zzz = age;

        for (uint i = 0; i < val_.length; i++) {
            // Validate the values were signed by an authorized oracle
            address signer = recover(val_[i], age_[i], v[i], r[i], s[i]);
            // Check that signer is an oracle
            require(orcl[signer] == 1, "Median/invalid-oracle");
            // Price feed age greater than last medianizer age
            require(age_[i] > zzz, "Median/stale-message");
            // Check for ordered values
            require(val_[i] >= last, "Median/messages-not-in-order");
            last = val_[i];
            // Bloom filter for signer uniqueness
            uint8 sl = uint8(uint256(signer) >> 152);
            require((bloom >> sl) % 2 == 0, "Median/oracle-already-signed");
            bloom += uint256(2) ** sl;
        }

        val = uint128(val_[val_.length >> 1]);
        age = uint32(block.timestamp);

        emit LogMedianPrice(val, age);
    }

    function lift(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "Median/no-oracle-0");
            uint8 s = uint8(uint256(a[i]) >> 152);
            require(slot[s] == address(0), "Median/signer-already-exists");
            orcl[a[i]] = 1;
            slot[s] = a[i];
        }
    }

    function drop(address[] calldata a) external auth {
       for (uint i = 0; i < a.length; i++) {
            orcl[a[i]] = 0;
            slot[uint8(uint256(a[i]) >> 152)] = address(0);
       }
    }

    function setBar(uint256 bar_) external auth {
        require(bar_ > 0, "Median/quorum-is-zero");
        require(bar_ % 2 != 0, "Median/quorum-not-odd-number");
        bar = bar_;
    }

    function kiss(address a) external auth {
        require(a != address(0), "Median/no-contract-0");
        bud[a] = 1;
    }

    function diss(address a) external auth {
        bud[a] = 0;
    }

    function kiss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "Median/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}

contract MockOsm {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "OSM/not-authorized");
        _;
    }

    // --- Stop ---
    uint256 public stopped;
    modifier stoppable { require(stopped == 0, "OSM/is-stopped"); _; }

    // --- Math ---
    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        z = x + y;
        require(z >= x);
    }

    address public src;
    uint16  constant ONE_HOUR = uint16(3600);
    uint16  public hop = ONE_HOUR;
    uint64  public zzz;

    struct Feed {
        uint128 val;
        uint128 has;
    }

    Feed cur;
    Feed nxt;

    // Whitelisted contracts, set by an auth
    mapping (address => uint256) public bud;

    modifier toll { require(bud[msg.sender] == 1, "OSM/contract-not-whitelisted"); _; }

    event LogValue(bytes32 val);

    constructor (address src_) public {
        wards[msg.sender] = 1;
        src = src_;
    }

    function stop() external auth {
        stopped = 1;
    }
    function start() external auth {
        stopped = 0;
    }

    function change(address src_) external auth {
        src = src_;
    }

    function era() internal view returns (uint) {
        return block.timestamp;
    }

    function prev(uint ts) internal view returns (uint64) {
        require(hop != 0, "OSM/hop-is-zero");
        return uint64(ts - (ts % hop));
    }

    function step(uint16 ts) external auth {
        require(ts > 0, "OSM/ts-is-zero");
        hop = ts;
    }

    function void() external auth {
        cur = nxt = Feed(0, 0);
        stopped = 1;
    }

    function pass() public view returns (bool ok) {
        return era() >= add(zzz, hop);
    }

    function poke() external stoppable {
        require(pass(), "OSM/not-passed");
        (bytes32 wut, bool ok) = DSValueAbstract(src).peek();
        if (ok) {
            cur = nxt;
            nxt = Feed(uint128(uint(wut)), 1);
            zzz = prev(era());
            emit LogValue(bytes32(uint(cur.val)));
        }
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint(cur.val)), cur.has == 1);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint(nxt.val)), nxt.has == 1);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has == 1, "OSM/no-current-value");
        return (bytes32(uint(cur.val)));
    }

    function kiss(address a) external auth {
        require(a != address(0), "OSM/no-contract-0");
        bud[a] = 1;
    }

    function diss(address a) external auth {
        bud[a] = 0;
    }

    function kiss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "OSM/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}

contract ActionTest is Test {
    ChainlogLike LOG = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    VatAbstract                  immutable vat = VatAbstract(LOG.getAddress("MCD_VAT"));
    EndAbstract                  immutable end = EndAbstract(LOG.getAddress("MCD_END"));
    VowAbstract                  immutable vow = VowAbstract(LOG.getAddress("MCD_VOW"));
    PotAbstract                  immutable pot = PotAbstract(LOG.getAddress("MCD_POT"));
    JugAbstract                  immutable jug = JugAbstract(LOG.getAddress("MCD_JUG"));
    DogAbstract                  immutable dog = DogAbstract(LOG.getAddress("MCD_DOG"));
    CatAbstract                  immutable cat = CatAbstract(LOG.getAddress("MCD_CAT"));
    DaiAbstract                  immutable daiToken = DaiAbstract(LOG.getAddress("MCD_DAI"));
    DaiJoinAbstract              immutable daiJoin = DaiJoinAbstract(LOG.getAddress("MCD_JOIN_DAI"));
    SpotAbstract                 immutable spot = SpotAbstract(LOG.getAddress("MCD_SPOT"));
    FlapAbstract                 immutable flap = FlapAbstract(LOG.getAddress("MCD_FLAP"));
    FlopAbstract                 immutable flop = FlopAbstract(LOG.getAddress("MCD_FLOP"));
    DSTokenAbstract              immutable gov = DSTokenAbstract(LOG.getAddress("MCD_GOV"));
    IlkRegistryAbstract          immutable reg = IlkRegistryAbstract(LOG.getAddress("ILK_REGISTRY"));
    OsmMomAbstract               immutable osmMom = OsmMomAbstract(LOG.getAddress("OSM_MOM"));
    ClipperMomAbstract           immutable clipperMom = ClipperMomAbstract(LOG.getAddress("CLIPPER_MOM"));
    MkrAuthorityAbstract         immutable govGuard = MkrAuthorityAbstract(LOG.getAddress("GOV_GUARD"));
    DssAutoLineAbstract          immutable autoLine = DssAutoLineAbstract(LOG.getAddress("MCD_IAM_AUTO_LINE"));
    LerpFactoryAbstract          immutable lerpFab = LerpFactoryAbstract(LOG.getAddress("LERP_FAB"));
    RwaLiquidationOracleLike     immutable rwaOracle = RwaLiquidationOracleLike(LOG.getAddress("MIP21_LIQUIDATION_ORACLE"));

    MedianAbstract immutable median = MedianAbstract(address(new MockMedian()));

    DssTestAction action;

    struct Ilk {
        DSValueAbstract pip;
        OsmAbstract     osm;
        DSTokenAbstract gem;
        GemJoinAbstract join;
        ClipAbstract    clip;
    }

    mapping (bytes32 => Ilk) ilks;

    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    uint256 immutable START_TIME = block.timestamp;
    string constant doc = "QmcniBv7UQ4gGPQQW2BwbD4ZZHzN3o3tPuNLZCbBchd1zh";

    address constant UNIV2ORACLE_FAB = 0xc968B955BCA6c2a3c828d699cCaCbFDC02402D89;

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
    // function gem(bytes32 ilk, address urn) internal view returns (uint) {
    //     return vat.gem(ilk, urn);
    // }
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

    /**
    * @notice Test that two values are approximately equal within a certain tolerance range
    * @param _a First value
    * @param _b Second value
    * @param _tolerance Maximum tolerated difference, in absolute terms
    */
    function assertEqApprox(uint256 _a, uint256 _b, uint256 _tolerance) internal {
        uint256 a = _a;
        uint256 b = _b;
        if (a < b) { // if a < b, switch values so that a is always the biggest amount
            uint256 tmp = a;
            a = b;
            b = tmp;
        }
        if (a - b > _tolerance) {
            emit log_bytes32("Error: Wrong `uint' value");
            emit log_named_uint("  Expected", _b);
            emit log_named_uint("    Actual", _a);
            fail();
        }
    }

    function giveAuth(address _base, address target) internal {
        WardsAbstract base = WardsAbstract(_base);

        // Edge case - ward is already set
        if (base.wards(target) == 1) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm.load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            vm.store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(1))
            );
            if (base.wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function init_collateral(bytes32 name, address _action) internal returns (Ilk memory) {
        DSTokenAbstract gem = DSTokenAbstract(address(new MockToken("")));
        gem.mint(address(this), 20 ether);

        DSValueAbstract pip = DSValueAbstract(address(new MockValue()));
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        OsmAbstract osm = OsmAbstract(address(new MockOsm(address(pip))));
        osm.rely(address(clipperMom));

        vat.init(name);
        GemJoinAbstract join = GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), name, address(gem)));

        vat.file(name, "line", rad(1000 ether));

        gem.approve(address(join), uint256(-1));

        vat.rely(address(join));

        ClipAbstract clip = ClipAbstract(ClipFabLike(LOG.getAddress("CLIP_FAB")).newClip(address(this), address(vat), address(spot), address(dog), name));
        vat.hope(address(clip));
        clip.rely(address(end));
        clip.rely(address(dog));
        dog.rely(address(clip));
        dog.file(name, "clip", address(clip));
        dog.file(name, "chop", 1 ether);
        dog.file("Hole", rad((10 ether) * MILLION));

        reg.add(address(join));

        clip.rely(_action);
        join.rely(_action);
        osm.rely(_action);

        ilks[name].pip = pip;
        ilks[name].osm = osm;
        ilks[name].gem = gem;
        ilks[name].join = join;
        ilks[name].clip = clip;

        return ilks[name];
    }

    function init_rwa(
        bytes32 ilk,
        uint256 line,
        uint48 tau,
        uint256 duty,
        uint256 mat
    ) internal {
        uint256 val = rmul(rmul(line / RAY, mat), rpow(duty, 2 * 365 days, RAY));
        rwaOracle.init(ilk, val, doc, tau);
        (,address pip,,) = rwaOracle.ilks(ilk);
        spot.file(ilk, "pip", pip);
        vat.init(ilk);
        jug.init(ilk);
        string memory name = string(abi.encodePacked(ilk));
        DSTokenAbstract token = DSTokenAbstract(RwaTokenFactoryLike(LOG.getAddress("RWA_TOKEN_FAB")).createRwaToken(name, name, address(this)));
        AuthGemJoinAbstract join = AuthGemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newAuthGemJoin(address(this), ilk, address(token)));
        vat.rely(address(join));
        vat.rely(address(rwaOracle));
        vat.file(ilk, "line", line);
        vat.file("Line", vat.Line() + line);
        jug.file(ilk, "duty", duty);
        spot.file(ilk, "mat", mat);
        spot.poke(ilk);
    }

    function setUp() public {
        vm.warp(START_TIME);

        action = new DssTestAction();

        giveAuth(address(vat), address(this));
        giveAuth(address(vat), address(action));
        giveAuth(address(spot), address(this));
        giveAuth(address(spot), address(action));
        giveAuth(address(dog), address(this));
        giveAuth(address(dog), address(action));
        giveAuth(address(vow), address(action));
        giveAuth(address(end), address(action));
        giveAuth(address(pot), address(action));
        giveAuth(address(jug), address(this));
        giveAuth(address(jug), address(action));
        giveAuth(address(flap), address(action));
        giveAuth(address(flop), address(action));
        giveAuth(address(daiJoin), address(action));
        giveAuth(address(LOG), address(action));
        giveAuth(address(reg), address(this));
        giveAuth(address(reg), address(action));
        giveAuth(address(autoLine), address(action));
        giveAuth(address(lerpFab), address(action));
        giveAuth(address(rwaOracle), address(this));
        giveAuth(address(rwaOracle), address(action));
        median.rely(address(action));

        init_collateral("gold", address(action));
        init_rwa({
            ilk:      "6s",
            line:     20_000_000 * RAD,
            tau:      365 days,
            duty:     1000000000937303470807876289, // 3% APY
            mat:      105 * RAY / 100
        });

        vm.store(address(clipperMom), 0, bytes32(uint256(address(action))));
        vm.store(address(osmMom), 0, bytes32(uint256(address(action))));

        vm.store(address(govGuard), 0, bytes32(uint256(address(action))));
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
        assertEq(clipperMom.authority(), address(LOG.getAddress("MCD_ADM")));
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
        assertEq(LOG.getAddress(ilk), address(this));
    }

    function test_setVersion() public {
        string memory version = "9001.0.0";
        action.setChangelogVersion_test(version);
        assertEq(LOG.version(), version);
    }

    function test_setIPFS() public {
        string memory ipfs = "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW";
        action.setChangelogIPFS_test(ipfs);
        assertEq(LOG.ipfs(), ipfs);
    }

    function test_setSHA256() public {
        string memory SHA256 = "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b";
        action.setChangelogSHA256_test(SHA256);
        assertEq(LOG.sha256sum(), SHA256);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/

    function test_accumulateDSR() public {
        uint256 beforeChi = pot.chi();
        action.setDSR_test(1000000001243680656318820312); // 4%
        vm.warp(START_TIME + 1 days);
        action.accumulateDSR_test();
        uint256 afterChi = pot.chi();

        assertTrue(afterChi - beforeChi > 0);
    }

    function test_accumulateCollateralStabilityFees() public {
        (, uint256 beforeRate,,,) = vat.ilks("gold");
        action.setDSR_test(1000000001243680656318820312); // 4%
        vm.warp(START_TIME + 1 days);
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

    function testFail_setMinDebtAuctionBidIncreaseTooHigh() public {
        action.setMinDebtAuctionBidIncrease_test(10000); // Fail on 100%
    }

    function test_setDebtAuctionBidDuration() public {
        action.setDebtAuctionBidDuration_test(12 hours);
        assertEq(uint256(flop.ttl()), 12 hours);
    }

    function testFail_setDebtAuctionBidDurationMax() public {
        action.setDebtAuctionBidDuration_test(type(uint48).max);  // Fail on max
    }

    function test_setDebtAuctionDuration() public {
        action.setDebtAuctionDuration_test(12 hours);
        assertEq(uint256(flop.tau()), 12 hours);
    }

    function testFail_setDebtAuctionDurationMax() public {
        action.setDebtAuctionDuration_test(type(uint48).max);  // Fail on max
    }

    function test_setDebtAuctionMKRIncreaseRate() public {
        action.setDebtAuctionMKRIncreaseRate_test(525);
        assertEq(flop.pad(), 105.25 ether / 100); // WAD pct
    }

    function testFail_setDebtAuctionMKRIncreaseRateTooHigh() public {
        action.setDebtAuctionMKRIncreaseRate_test(10000);  // Fail on 100%
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
        (,address pip,,) = rwaOracle.ilks("6s");
        uint256 price = uint256(PipLike(pip).read());
        assertEqApprox(price, 22_278_900 * WAD, WAD); // 20MM * 1.03^2 * 1.05
        action.setRWAIlkDebtCeiling_test("6s", 50 * MILLION, 55 * MILLION); // Increase
        (,,, uint256 line,) = vat.ilks("6s");
        assertEq(line, 50 * MILLION * RAD);
        price = uint256(PipLike(pip).read());
        assertEq(price, 55 * MILLION * WAD);
        action.setRWAIlkDebtCeiling_test("6s", 40 * MILLION, 55 * MILLION); // Decrease
        (,,, line,) = vat.ilks("6s");
        assertEq(line, 40 * MILLION * RAD);
        price = uint256(PipLike(pip).read());
        assertEq(price, 55 * MILLION * WAD);
    }

    function testFail_setRWAIlkDebtCeiling() public {
        action.setRWAIlkDebtCeiling_test("6s", 50 * MILLION, 20 * MILLION); // Fail
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
        vm.warp(START_TIME + 1 days);
        action.setIlkStabilityFee_test("gold", 1000000001243680656318820312);
        (uint256 duty, uint256 rho) = jug.ilks("gold");
        assertEq(duty, 1000000001243680656318820312);
        assertEq(rho, START_TIME + 1 days);
    }

    /**************************/
    /*** Pricing Management ***/
    /**************************/

    function test_setLinearDecrease() public {
        LinearDecreaseAbstract calc = LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        calc.rely(address(action));
        action.setLinearDecrease_test(address(calc), 14 hours);
        assertEq(calc.tau(), 14 hours);
    }

    function test_setStairstepExponentialDecrease() public {
        StairstepExponentialDecreaseAbstract calc = StairstepExponentialDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newStairstepExponentialDecrease(address(this)));
        calc.rely(address(action));
        action.setStairstepExponentialDecrease_test(address(calc), 90, 9999); // 90 seconds per step, 99.99% multiplicative
        assertEq(calc.step(), 90);
        assertEq(calc.cut(), 999900000000000000000000000);
    }

    function test_setExponentialDecrease() public {
        ExponentialDecreaseAbstract calc = ExponentialDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newExponentialDecrease(address(this)));
        calc.rely(address(action));
        action.setExponentialDecrease_test(address(calc), 9999); // 99.99% multiplicative
        assertEq(calc.cut(), 999900000000000000000000000);
    }


    /*************************/
    /*** Oracle Management ***/
    /*************************/

    function test_whitelistOracle_OSM() public {
        address tokenPip = address(new MockOsm(address(median)));

        assertEq(median.bud(tokenPip), 0);
        action.whitelistOracleMedians_test(tokenPip);
        assertEq(median.bud(tokenPip), 1);
    }

    function test_whitelistOracle_LP() public {
        // Mock an LP oracle and whitelist it
        address token0 = address(new MockToken("nil"));
        address token1 = address(new MockToken("one"));
        MedianAbstract  med0   = MedianAbstract(address(new MockMedian()));
        MedianAbstract  med1   = MedianAbstract(address(new MockMedian()));
        address lperc  = address(new MockUniPair(token0, token1));
        med0.rely(address(action));
        med1.rely(address(action));
        LPOsmAbstract lorc = LPOsmAbstract(Univ2OracleFactoryLike(UNIV2ORACLE_FAB).build(address(this), address(lperc), "NILONE", address(med0), address(med1)));

        assertEq(med0.bud(address(lorc)), 0);
        assertEq(med1.bud(address(lorc)), 0);
        action.whitelistOracleMedians_test(address(lorc));
        assertEq(med0.bud(address(lorc)), 1);
        assertEq(med1.bud(address(lorc)), 1);
    }

    function test_whitelistOracleWithDSValue_LP() public {
        // Should not fail for LP tokens if one or more oracles are DSValue
        address token0 = address(new MockToken("nil"));
        address token1 = address(new MockToken("one"));
        DSValueAbstract med0   = DSValueAbstract(address(new MockValue()));
        DSValueAbstract med1   = DSValueAbstract(address(new MockValue()));
        address lperc  = address(new MockUniPair(token0, token1));
        med0.poke(bytes32(uint256(100)));
        med1.poke(bytes32(uint256(100)));
        LPOsmAbstract lorc = LPOsmAbstract(Univ2OracleFactoryLike(UNIV2ORACLE_FAB).build(address(this), address(lperc), "NILONE", address(med0), address(med1)));

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
        OsmAbstract osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
    }

    function test_removeReaderFromOSMWhitelist() public {
        OsmAbstract osm = ilks["gold"].osm;
        address reader = address(1);

        assertEq(osm.bud(address(1)), 0);
        action.addReaderToWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 1);
        action.removeReaderFromWhitelist_test(address(osm), reader);
        assertEq(osm.bud(address(1)), 0);
    }

    function test_allowOSMFreeze() public {
        OsmAbstract osm = ilks["gold"].osm;
        action.allowOSMFreeze_test(address(osm), "gold");
        assertEq(osmMom.osms("gold"), address(osm));
    }

    /*****************************/
    /*** Direct Deposit Module ***/
    /*****************************/

    function test_setD3MTargetInterestRate() public {
        D3MLike d3m = D3MLike(LOG.getAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"));
        giveAuth(address(d3m), address(action));

        action.setD3MTargetInterestRate_test(address(d3m), 500); // set to 5%
        assertEq(d3m.bar(), 5 * RAY / 100);

        action.setD3MTargetInterestRate_test(address(d3m), 0);   // set to 0%
        assertEq(d3m.bar(), 0);

        action.setD3MTargetInterestRate_test(address(d3m), 1000); // set to 10%
        assertEq(d3m.bar(), 10 * RAY / 100);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function test_collateralOnboardingBase() public {
        string memory silk = "silver";
        bytes32 ilk = stringToBytes32(silk);

        DSTokenAbstract token     = DSTokenAbstract(address(new MockToken(silk)));
        GemJoinAbstract tokenJoin = GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), ilk, address(token)));
        ClipAbstract tokenClip = ClipAbstract(ClipFabLike(LOG.getAddress("CLIP_FAB")).newClip(address(this), address(vat), address(spot), address(dog), ilk));
        LinearDecreaseAbstract tokenCalc = LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        tokenCalc.file("tau", 1);
        address tokenPip  = address(DSValueAbstract(address(new MockValue())));

        tokenPip = address(new MockOsm(address(tokenPip)));
        OsmAbstract(tokenPip).rely(address(action));
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

        address token     = address(new MockToken(silk));
        GemJoinAbstract tokenJoin = GemJoinAbstract(GemJoinFabLike(LOG.getAddress("JOIN_FAB")).newGemJoin(address(this), ilk, address(token)));
        ClipAbstract tokenClip = ClipAbstract(ClipFabLike(LOG.getAddress("CLIP_FAB")).newClip(address(this), address(vat), address(spot), address(dog), ilk));
        LinearDecreaseAbstract tokenCalc = LinearDecreaseAbstract(CalcFabLike(LOG.getAddress("CALC_FAB")).newLinearDecrease(address(this)));
        tokenCalc.file("tau", 1);
        address tokenPip  = address(DSValueAbstract(address(new MockValue())));

        if (isOsm) {
            tokenPip = medianSrc ? address(new MockOsm(address(median))) : address(new MockOsm(address(tokenPip)));
            OsmAbstract(tokenPip).rely(address(action));
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
            assertEq(OsmAbstract(tokenPip).wards(address(osmMom)),     1);
            assertEq(OsmAbstract(tokenPip).bud(address(spot)),         1);
            assertEq(OsmAbstract(tokenPip).bud(address(tokenClip)),    1);
            assertEq(OsmAbstract(tokenPip).bud(address(clipperMom)),   1);
            assertEq(OsmAbstract(tokenPip).bud(address(end)),          1);

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
        vm.warp(now + 1 hours);
        assertEq(vat.Line(), rad(2400 ether));
        lerp.tick();
        assertEq(vat.Line(), rad(2300 ether + 1600));   // Small amount at the end is rounding errors
        vm.warp(now + 1 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(2200 ether + 800));
        vm.warp(now + 6 hours);
        lerp.tick();
        assertEq(vat.Line(), rad(1600 ether + 800));
        vm.warp(now + 1 days);
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
        vm.warp(now + 1 hours);
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2400 ether));
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2300 ether + 1600));   // Small amount at the end is rounding errors
        vm.warp(now + 1 hours);
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(2200 ether + 800));
        vm.warp(now + 6 hours);
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        vm.warp(now + 1 days);
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(1600 ether + 800));
        lerp.tick();
        (,,,line,) = vat.ilks(ilk);
        assertEq(line, rad(0 ether));
        assertTrue(lerp.done());
        assertEq(vat.wards(address(lerp)), 0);
    }
}

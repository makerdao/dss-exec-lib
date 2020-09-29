pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./DssExec.sol";
import "./DssExecLib.sol";

contract DssSpellActionTest {
    using DssExecLib for *;



}

contract DssSpellTest is DssExec(
    "A test dss exec spell",                    // Description
    now + 30 days,                              // Expiration
    true,                                       // OfficeHours enabled
    address(new DssSpellActionTest())) {}       // Use the action above

contract DssLibExecTest is DSTest {

    DssSpellTest dssTest;

    function setUp() public {
        dssTest = new DssSpellTest();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}

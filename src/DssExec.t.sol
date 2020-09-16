pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./DssExec.sol";
import "./DssExecLib.sol";

contract DssSpellAction {
    using DssExecLib for *;



}

contract DssSpellTest is DssExec("A test dss exec spell", now, true, address(new DssSpellAction())) {

}

contract DssLibExecTest is DSTest {

    function setUp() public {

    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}

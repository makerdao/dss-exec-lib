pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./DssLibExec.sol";

contract DssLibExecTest is DSTest {
    DssLibExec exec;

    function setUp() public {
        exec = new DssLibExec();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}

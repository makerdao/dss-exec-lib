pragma solidity ^0.6.7;

abstract contract DssAction {

    address public immutable lib;

    constructor(address lib_) public {
        lib = lib_;
    }

    function _dcall(bytes memory data) internal {
        (bool ok,) = lib.delegatecall(data);
        require(ok, "fail");
    }

    // TODO Additional libcall functions for different parameter inputs, and a generic bytes param
    function libCall(string memory sig, uint256 amount) internal {
        _dcall(abi.encodeWithSignature(sig, amount));
    }

    function libCall(string memory sig, bytes32 thing, uint256 amount) internal {
        _dcall(abi.encodeWithSignature(sig, abi.encodePacked(thing, amount)));
    }

    // TODO Optional explicit setter for usability
    function setGlobalLine(uint256 amount) internal {
        libCall("setGlobalLine(uint256)", amount);
    }

    // Abstract enforcement of required execute() function
    function execute() external virtual;
}

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

    function libCall(string memory sig) internal {
        _dcall(abi.encodeWithSignature(sig));
    }

    function libCall(string memory sig, uint256 amount) internal {
        _dcall(abi.encodeWithSignature(sig, amount));
    }

    function libCall(string memory sig, bytes32 thing) internal {
        _dcall(abi.encodeWithSignature(sig, thing));
    }

    function libCall(string memory sig, bytes32 thing, uint256 amount) internal {
        _dcall(abi.encodeWithSignature(sig, thing, amount));
    }

    function libCall(string memory sig, address addr, uint256 amount) internal {
        _dcall(abi.encodeWithSignature(sig, addr, amount));
    }

    function setGlobalLine(uint256 amount) internal {
        libCall("setGlobalLine(uint256)", amount);
    }

    function setIlkLine(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkLine(bytes32,uint256)", ilk, amount);
    }

    function setDsr(uint256 rate) internal {
        libCall("setDSR(uint256)", rate);
    }

    function setStabilityFee(bytes32 ilk, uint256 rate) internal {
        libCall("setStabilityFee(bytes32,uint256)", ilk, rate);
    }

    // Abstract enforcement of required execute() function
    function execute() external virtual;
}

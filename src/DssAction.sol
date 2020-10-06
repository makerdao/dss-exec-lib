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

    function drip() internal {
        libCall("drip()");
    }

    function drip(bytes32 ilk) internal {
        libCall("drip(bytes32)", ilk);
    }

    function setGlobalDebtCeiling(uint256 amount) internal {
        libCall("setGlobalDebtCeiling(uint256)", amount);
    }

    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkLine(bytes32,uint256)", ilk, amount);
    }

    function setDSR(uint256 rate) internal {
        libCall("setDSR(uint256)", rate);
    }

    function setStabilityFee(bytes32 ilk, uint256 rate) internal {
        libCall("setStabilityFee(bytes32,uint256)", ilk, rate);
    }

    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMinVaultAmount(bytes32,uint256)", ilk, amount);
    }

    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct) internal {
        libCall("setIlkLiquidationPenalty(bytes32,uint256)", ilk, pct);
    }

    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMaxLiquidationAmount(bytes32,uint256)", ilk, amount);
    }

    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct) internal {
        libCall("setIlkLiquidationRatio(bytes32,uint256)", ilk, pct);
    }

    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct) internal {
        libCall("setIlkMinAuctionBidIncrease(bytes32,uint256)", ilk, pct);
    }

    function setIlkBidDuration(bytes32 ilk, uint256 length) internal {
        libCall("setIlkBidDuration(bytes32,uint256)", ilk, length);
    }

    function setIlkAuctionDuration(bytes32 ilk, uint256 length) internal {
        libCall("setIlkAuctionDuration(bytes32,uint256)", ilk, length);
    }

    // Abstract enforcement of required execute() function
    function execute() external virtual;
}

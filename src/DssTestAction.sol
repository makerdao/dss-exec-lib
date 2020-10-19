pragma solidity ^0.6.7;

import "./DssAction.sol";

contract DssTestAction is DssAction {

    constructor(address lib) DssAction(lib) public {}

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize_test(address base, address ward) public {
        authorize(base, ward);
    }

    function deauthorize_test(address base, address ward) public {
        deauthorize(base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR_test() public {
        accumulateDSR();
    }

    function accumulateCollateralStabilityFees_test(bytes32 ilk) public {
        accumulateCollateralStabilityFees(ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice_test(bytes32 ilk) public {
        updateCollateralPrice(ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract_test(address base, bytes32 what, address addr) public {
        setContract(base, what, addr);
    }

    function setContract_test(address base, bytes32 ilk, bytes32 what, address addr) public {
        setContract(base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling_test(uint256 amount) public {
        setGlobalDebtCeiling(amount);
    }

    function setDSR_test(uint256 rate) public {
        setDSR(rate);
    }

    function setSurplusAuctionAmount_test(uint256 amount) public { 
        setSurplusAuctionAmount(amount);
    }

    function setSurplusBuffer_test(uint256 amount) public { 
        setSurplusBuffer(amount);
    }

    function setMinSurplusAuctionBidIncrease_test(uint256 pct) public { 
        setMinSurplusAuctionBidIncrease(pct);
    }

    function setSurplusAuctionBidDuration_test(uint256 length) public { 
        setSurplusAuctionBidDuration(length);
    }

    function setSurplusAuctionDuration_test(uint256 length) public { 
        setSurplusAuctionDuration(length);
    }

    function setDebtAuctionDelay_test(uint256 length) public { 
        setDebtAuctionDelay(length);
    }

    function setDebtAuctionDAIAmount_test(uint256 amount) public { 
        setDebtAuctionDAIAmount(amount);
    }

    function setDebtAuctionMKRAmount_test(uint256 amount) public { 
        setDebtAuctionMKRAmount(amount);
    }

    function setMinDebtAuctionBidIncrease_test(uint256 pct) public { 
        setMinDebtAuctionBidIncrease(pct);
    }

    function setDebtAuctionBidDuration_test(uint256 length) public { 
        setDebtAuctionBidDuration(length);
    }

    function setDebtAuctionDuration_test(uint256 length) public { 
        setDebtAuctionDuration(length);
    }

    function setDebtAuctionMKRIncreaseRate_test(uint256 pct) public { 
        setDebtAuctionMKRIncreaseRate(pct);
    }

    function setMaxTotalDAILiquidationAmount_test(uint256 amount) public { 
        setMaxTotalDAILiquidationAmount(amount);
    }

    function setEmergencyShutdownProcessingTime_test(uint256 length) public { 
        setEmergencyShutdownProcessingTime(length);
    }

    function setGlobalStabilityFee_test(uint256 rate) public { 
        setGlobalStabilityFee(rate);
    }

    function setDAIReferenceValue_test(uint256 amount) public { 
        setDAIReferenceValue(amount);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        setIlkDebtCeiling(ilk, amount);
    }

    function setIlkMinVaultAmount_test(bytes32 ilk, uint256 amount) public {
        setIlkMinVaultAmount(ilk, amount);
    }

    function setIlkLiquidationPenalty_test(bytes32 ilk, uint256 pct) public {
        setIlkLiquidationPenalty(ilk, pct);
    }

    function setIlkMaxLiquidationAmount_test(bytes32 ilk, uint256 amount) public {
        setIlkMaxLiquidationAmount(ilk, amount);
    }

    function setIlkLiquidationRatio_test(bytes32 ilk, uint256 pct) public {
        setIlkLiquidationRatio(ilk, pct);
    }

    function setIlkMinAuctionBidIncrease_test(bytes32 ilk, uint256 pct) public {
        setIlkMinAuctionBidIncrease(ilk, pct);
    }

    function setIlkBidDuration_test(bytes32 ilk, uint256 length) public {
        setIlkBidDuration(ilk, length);
    }

    function setIlkAuctionDuration_test(bytes32 ilk, uint256 length) public {
        setIlkAuctionDuration(ilk, length);
    }

    function setIlkStabilityFee_test(bytes32 ilk, uint256 rate) public {
        setIlkStabilityFee(ilk, rate);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract_test(bytes32 ilk, address newFlip, address oldFlip) public {
        updateCollateralAuctionContract(ilk, newFlip, oldFlip);
    }

    function updateSurplusAuctionContract_test(bytes32 ilk, address newFlap, address oldFlap) public {
        updateSurplusAuctionContract(ilk, newFlap, oldFlap);
    }

    function updateDebtAuctionContract_test(bytes32 ilk, address newFlop, address oldFlop) public {
        updateDebtAuctionContract(ilk, newFlop, oldFlop);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        addWritersToMedianWhitelist(medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        removeWritersFromMedianWhitelist(medianizer, feeds);
    }

    function addReadersToMedianWhitelist_test(address medianizer, address[] memory readers) public {
        addReadersToMedianWhitelist(medianizer, readers);
    }

    function addReaderToMedianWhitelist_test(address medianizer, address reader) public {
        addReaderToMedianWhitelist(medianizer, reader);
    }

    function removeReadersFromMedianWhitelist_test(address medianizer, address[] memory readers) public {
        removeReadersFromMedianWhitelist(medianizer, readers);
    }

    function removeReaderFromMedianWhitelist_test(address medianizer, address reader) public {
        removeReaderFromMedianWhitelist(medianizer, reader);
    }

    function setMedianWritersQuorum_test(address medianizer, uint256 minQuorum) public {
        setMedianWritersQuorum(medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist_test(address osm, address reader) public {
        addReaderToOSMWhitelist(osm, reader);
    }

    function removeReaderFromOSMWhitelist_test(address osm, address reader) public {
        removeReaderFromOSMWhitelist(osm, reader);
    }

    function allowOSMFreeze_test(address osm, bytes32 ilk) public {
        allowOSMFreeze(osm, ilk);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/
    function addNewCollateral_test(
        bytes32          ilk,
        address[] memory addresses,
        bool             liquidatable,
        bool[] memory    oracleSettings,
        uint256          ilkDebtCeiling,
        uint256          minVaultAmount,
        uint256          maxLiquidationAmount,
        uint256          liquidationPenalty,
        uint256          ilkStabilityFee,
        uint256          bidIncrease,
        uint256          bidDuration,
        uint256          auctionDuration,
        uint256          liquidationRatio
    ) public {
        addNewCollateral(
            ilk, 
            addresses, 
            liquidatable, 
            oracleSettings,
            ilkDebtCeiling, 
            minVaultAmount, 
            maxLiquidationAmount, 
            liquidationPenalty, 
            ilkStabilityFee, 
            bidIncrease, 
            bidDuration, 
            auctionDuration, 
            liquidationRatio
        );
    }

    // // Abstract enforcement of required execute() function
    // function execute() external override {}
}

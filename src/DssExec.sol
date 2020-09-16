pragma solidity ^0.6.7;

interface DSPauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

contract DssExec {

    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d8496d07a5eae08f2d1886f6bf4de1a813b4584d/governance/votes/Executive%20vote%20-%20September%204%2C%202020.md -q -O - 2>/dev/null)"
    string          public description;

    bool            private officeHours;
    address         private spellAction;

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _officeHours  Limits the executive cast time to office hours (true for limit)
    // @param _spellAction  The address of the spell action
    constructor(string memory _description, uint256 _expiration, bool _officeHours, address _spellAction) public {
        description = _description;
        expiration  = _expiration;
        officeHours = _officeHours;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        action = address(action);
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    modifier limited {
        if(officeHours) {
            uint day = (now / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = now / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() limited public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

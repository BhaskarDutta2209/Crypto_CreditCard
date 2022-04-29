// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUserContract {
    function canCharge(uint256 _amount) external view returns (bool);

    function charge(uint256 _amount, bytes memory _signature) external;

    function recover(bytes32 _ethSignedMessageHash, bytes memory _signature)
        external
        pure
        returns (address);

    function _split(bytes memory _signature)
        external
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        );

    function flush() external;

}

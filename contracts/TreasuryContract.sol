// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TreasuryContract {
    AggregatorV3Interface internal priceFeed;

    address private WETH;
    address private router;
    address private owner;
    address private ccIssuer;

    mapping(address => bool) private isValidCC;

    event FundsTransfered(
        address indexed from,
        address indexed to,
        uint256 amount,
        address token
    );

    constructor(
        address _aggregatorAddress,
        address _router,
        address _WETH
    ) {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
        router = _router;
        WETH = _WETH;
        owner = msg.sender;
        ccIssuer = msg.sender;
    }

    function sendToken(
        uint256 _amount,
        uint8 _inDecimals,
        address _targetToken,
        address _sender,
        address _receiver
    ) public {
        require(isValidCC[msg.sender], "Sender is not a valid CC");

        // Call Chainlink Price feed to get the current price of ETH.
        uint8 decimals = priceFeed.decimals();

        (, int256 price, , , ) = priceFeed.latestRoundData();

        price = scalePrice(price, decimals, _inDecimals); // Scale the price to the input's decimal system
        int256 amtOfEthNeeded = (int256(_amount) * int256(10**_inDecimals)) /
            price;

        if (_targetToken == address(0)) {
            // Send ETH to the target address
            payable(_receiver).transfer(uint256(amtOfEthNeeded));
        } else {
            // Calculate the amount of target token based on Uniswap
            uint256 amountOfToken = calculateAmountOfTokenNeeded(
                uint256(amtOfEthNeeded),
                _targetToken
            );
            IERC20 token = IERC20(_targetToken);
            require(token.balanceOf(address(this)) >= amountOfToken);
            token.transfer(_receiver, amountOfToken);
        }
        
        emit FundsTransfered(_sender, _receiver, _amount, _targetToken);
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function calculateAmountOfTokenNeeded(
        uint256 _amountOfEth,
        address _targetToken
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _targetToken;
        uint256[] memory outputAmounts = IUniswapV2Router02(payable(router))
            .getAmountsOut(_amountOfEth, path);
        return outputAmounts[1];
    }

    function withdrawFunds(
        uint256 _amount,
        address _tokenAddress,
        address _receiver
    ) public {
        require(msg.sender == owner, "Only the owner can withdraw");
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Not enough fund to withdraw"
        );
        token.transfer(_receiver, _amount);
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership");
        owner = _newOwner;
    }

    function setCCIssuer(address _ccIssuer) public {
        require(msg.sender == owner, "Only the owner can set the CC Issuer");
        ccIssuer = _ccIssuer;
    }

    function addCCAddress(address _ccAddress) public {
        require(msg.sender == ccIssuer, "Only the CC Issuer can add a CC address");
        isValidCC[_ccAddress] = true;
    }

    function removeCCAddress(address _ccAddress) public {
        require(msg.sender == owner, "Only the owner can remove a CC address");
        isValidCC[_ccAddress] = false;
    }
}

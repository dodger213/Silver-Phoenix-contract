// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SilverPhoenix is Context, Ownable, ERC20 {
    using Address for address payable;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    /// @dev Fee settings
    uint8 feeBuy = 4;
    uint8 feeSell = 4;
    uint8 feeTransfer = 4;
    address feeReceiver = 0xA58f9ff087a85a9B2b1cF07492Dd4808f4835B9B;

    uint256 swapTokenAmount;

    mapping(address => bool) private _isExcludedFromFee;

    event FeeReceiverChanged(
        address indexed oldFeeReceiver,
        address indexed newFeeReceiver
    );
    event SwapAmountChanged(
        uint256 indexed oldSwapAmount,
        uint256 indexed newSwapAmount
    );
    event ExcludedFromFee(address indexed account, bool excluded);
    event SwapAndSendFee(uint256 tokenSwapped, uint256 bnbSend);

    constructor() ERC20("Silver Phoenix", "SPX") Ownable(msg.sender) {

        _mint(msg.sender, 1e9 * 10 ** decimals());
        swapTokenAmount = totalSupply() / 5000;

        //Exclude fee on specific account
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeReceiver] = true;
        _isExcludedFromFee[address(0)] = true;

    }
}

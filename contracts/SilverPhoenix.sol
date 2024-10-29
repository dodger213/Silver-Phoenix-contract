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

    bool swapEnabled;

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
        address router;
        address pinkLock;

        if (block.chainid == 56) {
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
            pinkLock = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE; // BSC PinkLock
        } else if (block.chainid == 97) {
            router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
            pinkLock = 0x5E5b9bE5fd939c578ABE5800a90C566eeEbA44a5; // BSC Testnet PinkLock
        } else if (block.chainid == 1 || block.chainid == 5) {
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
            pinkLock = 0x71B5759d73262FBb223956913ecF4ecC51057641; // ETH PinkLock
        } else {
            revert();
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _mint(msg.sender, 1e9 * 10 ** decimals());
        swapTokenAmount = totalSupply() / 5000;

        //Exclude fee on specific account
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeReceiver] = true;
        _isExcludedFromFee[address(0)] = true;
    }

    /**
     * @dev internal function for transferring tokens
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param amount The amount of tokens to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    }

    /**
     * @dev internal function for handling fee
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param amount The amount of tokens to transfer
     */
    function _handleFee(address from, address to, uint256 amount) internal {
        if (from != uniswapV2Pair && to != uniswapV2Pair) {
            _transfer(from, to, amount);
            return;
        }

        uint256 feeAmount = 0;
        if (from == uniswapV2Pair) {
            feeAmount = (amount * feeBuy) / 100;
        } else if (to == uniswapV2Pair) {
            feeAmount = (amount * feeSell) / 100;
        } else {
            feeAmount = (amount * feeTransfer) / 100;
        }

        if (feeAmount > 0) {
            _transfer(from, feeReceiver, feeAmount);
            amount -= feeAmount;
            _transfer(from, to, amount);
        } else {
            _transfer(from, to, amount);
        }
    }
}

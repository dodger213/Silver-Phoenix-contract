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

    /// @dev Minimum amount of tokens accumulated with to swap to ETH/BNB
    uint256 swapTokenAmount;

    /// @dev Swap settings
    bool swapEnabled;
    bool swapping;
    bool tradingEnabled;

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
        _isExcludedFromFee[pinkLock] = true;
    }

    /**
     * @dev Help function to return decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
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
        require(
            tradingEnabled ||
                _isExcludedFromFee[from] ||
                _isExcludedFromFee[to],
            "Trading is not enabled yet"
        );

        //Swap SPX tokens accumulated with fee in contract to ETH/BNB
        uint256 accumulatedFeeTokenAmount = balanceOf(address(this));
        bool canSwap = accumulatedFeeTokenAmount >= swapTokenAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            to == uniswapV2Pair &&
            !_isExcludedFromFee[from]
        ) {
            swapping = true;
            _swapAndSendFee(accumulatedFeeTokenAmount);
            swapping = false;
        }

        //Calculate fee and transfer tokens and fee
        uint256 totalFees;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || swapping) {
            totalFees = 0;
        } else if (from == uniswapV2Pair) {
            //Buy
            totalFees = feeBuy;
        } else if (to == uniswapV2Pair) {
            //Sell
            totalFees = feeSell;
        } else {
            //Transsfer
            totalFees = feeTransfer;
        }

        if (totalFees > 0) {
            uint256 feeTokenAmount = (amount * totalFees) / 100;
            amount = amount - feeTokenAmount;
            super._transfer(from, address(this), feeTokenAmount);
        }
        super._transfer(from, to, amount);
    }

    /**
     * @dev internal function for handling swap and send fee
     * @param tokenAmount The amount of tokens to swap and send
     */
    function _swapAndSendFee(uint256 tokenAmount) internal {
        //Calculate initial balance
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        //Swap tokens for ETH
        try
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                feeReceiver,
                block.timestamp
            )
        {} catch {
            return;
        }
        //Calculate new balance
        uint256 newBalance = address(this).balance - initialBalance;

        //Send Fee to fee receiver
        payable(feeReceiver).sendValue(newBalance);
        emit SwapAndSendFee(tokenAmount, address(this).balance);
    }

    /**
     *@dev public function for changing fee receiver
     *@param newFeeReceiver_ The address of the new fee receiver
     */
    function changeFeeReceiver(address newFeeReceiver_) external onlyOwner {
        address oldReceiver = feeReceiver;
        feeReceiver = newFeeReceiver_;
        emit FeeReceiverChanged(oldReceiver, feeReceiver);
    }

    /**
     * @dev claim stuck tokens from contract
     *@param token The address of the token to claim
     */
    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
        }
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     *@dev exclude from fee
     *@param account The address of the account to exclude from fee
     *@param excluded Whether the account should be excluded from fee
     */
    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        _isExcludedFromFee[account] = excluded;
        emit ExcludedFromFee(account, excluded);
    }

    /**
     *@dev check if an account is excluded from fee
     *@param account The address of the account to check
     */
    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     *@dev set Swap Token Amount
     *@param newSwapTokenAmount The new swap token amount
     *@param _swapEnabled Whether to enable swap
     */
    function setSwapTokenAmount(
        uint256 newSwapTokenAmount,
        bool _swapEnabled
    ) external onlyOwner {
        require(
            newSwapTokenAmount >= totalSupply() / 1_000_000,
            "Swap Token Amount must be greater than 0.0001% of total supply"
        );
        uint256 oldSwapTokenAmount = swapTokenAmount;
        swapTokenAmount = newSwapTokenAmount;
        swapEnabled = _swapEnabled;
        emit SwapAmountChanged(oldSwapTokenAmount, newSwapTokenAmount);
    }

    /**
     *@dev enable trading and swap
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        swapEnabled = true;
    }

    receive() external payable {}
}

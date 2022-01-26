// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract SHIBACHARTS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public _liquidityFee;
    uint256 public _marketingFee;
    uint256 public _innovationFee;
    uint256 public _additionalTaxIfAny; // to prevent snipers

    address payable public liquidityAddress;
    address payable public marketingAddress;
    address payable public innovationAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private _tTotal;

    bool public tradingOpen = true;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_,
        uint256 liquidityFee_,
        uint256 marketingFee_,
        uint256 innovationFee_,
        address lpAddress_,
        address marketingAddress_,
        address innovationAddress_,
        address uniswapV2Router_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _liquidityFee = liquidityFee_;
        _marketingFee = marketingFee_;
        _innovationFee = innovationFee_;
        _additionalTaxIfAny = 0;

        liquidityAddress = payable(lpAddress_);
        marketingAddress = payable(marketingAddress_);
        innovationAddress = payable(innovationAddress_);

        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);

        _tTotal = tokenSupply_ * (10**decimals_);
        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        initContract();
    }

    function initContract() internal {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(innovationAddress)] = true;
        _isExcludedFromFee[address(marketingAddress)] = true;
        _isExcludedFromFee[address(liquidityAddress)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
    }

    function closeTrading() external onlyOwner {
        tradingOpen = false;
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(tradingOpen, "trading is not open for this contract.");

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 txnLt = (totalSupply() / 100) * 1;
        uint256 walletLt = (totalSupply() / 100) * 3;

        if (isBuy(from, to) && !isExcludedFromFee(to)) {
            require(amount <= txnLt, "txn amount exceeds 1% limit");
            require(
                _tOwned[to] + amount <= walletLt,
                "wallet bal will exceed 3%"
            );
            _tokenTransferWithTax(from, to, amount);
        } else if (isSell(from, to) && !isExcludedFromFee(from)) {
            require(amount <= txnLt, "txn amount exceeds 1% limit");
            _tokenTransferWithTax(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }
    }

    function isExcludedFromFee(address addr) public view returns (bool) {
        return _isExcludedFromFee[addr];
    }

    function isBuy(address sender, address recipient)
        private
        view
        returns (bool)
    {
        return sender == uniswapV2Pair && recipient != owner();
    }

    function isSell(address sender, address recipient)
        private
        view
        returns (bool)
    {
        return recipient == uniswapV2Pair && sender != owner();
    }

    function _tokenTransferWithTax(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 liquidityTax,
            uint256 marketingTax,
            uint256 innovationTax,
            uint256 additionalTax
        ) = calculateTax(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _tOwned[liquidityAddress] += liquidityTax;
        _tOwned[marketingAddress] += marketingTax;
        _tOwned[innovationAddress] += innovationTax;
        _tOwned[marketingAddress] += additionalTax;

        uint256 xfrAmt = tAmount
            .sub(liquidityTax)
            .sub(marketingTax)
            .sub(innovationTax)
            .sub(additionalTax);

        _tOwned[recipient] += xfrAmt;

        emit Transfer(sender, liquidityAddress, liquidityTax);
        emit Transfer(sender, marketingAddress, marketingTax + additionalTax);
        emit Transfer(sender, innovationAddress, innovationTax);
        emit Transfer(sender, recipient, xfrAmt);
    }

    function calculateTax(uint256 _amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _amount.mul(_liquidityFee).div(10**2),
            _amount.mul(_marketingFee).div(10**2),
            _amount.mul(_innovationFee).div(10**2),
            _amount.mul(_additionalTaxIfAny).div(10**2)
        );
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function excludeFromFee(address addr) public onlyOwner {
        _isExcludedFromFee[addr] = true;
    }

    function includeFromFee(address addr) public onlyOwner {
        _isExcludedFromFee[addr] = false;
    }

    function updateadditionalTaxIfAny(uint256 fee) public onlyOwner {
        require(fee >= 15, "minimum tax can be 15% to support the project");
        _additionalTaxIfAny = fee - 15;
    }

    function totalTax() public view returns (uint256) {
        return
            _liquidityFee +
            _marketingFee +
            _innovationFee +
            _additionalTaxIfAny;
    }
}

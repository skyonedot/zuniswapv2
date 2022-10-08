// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/ZuniswapV2Factory.sol";
import "../src/ZuniswapV2Pair.sol";
import "../src/libraries/UQ112x112.sol";
import "./mocks/ERC20Mintable.sol";

contract ZuniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ZuniswapV2Pair pair;
    TestUser testUser;
    // event Log(string message, uint256 value);

    function setUp() public {
        testUser = new TestUser();

        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");


        ZuniswapV2Factory factory = new ZuniswapV2Factory();
        address pairAddress = factory.createPair(
            address(token0),
            address(token1)
        );
        pair = ZuniswapV2Pair(pairAddress);

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        token0.mint(10 ether, address(testUser));
        token1.mint(10 ether, address(testUser));
    }

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function encodeError(string memory error, uint256 a)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error, a);
    }

    // 计算Reserve, Reserve是写在账本上的数据, 不如balance更新的快
    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1)
        internal
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    // 计算Price
    function assertCumulativePrices(
        uint256 expectedPrice0,
        uint256 expectedPrice1
    ) internal {
        assertEq(
            pair.price0CumulativeLast(),
            expectedPrice0,
            "unexpected cumulative price 0"
        );
        assertEq(
            pair.price1CumulativeLast(),
            expectedPrice1,
            "unexpected cumulative price 1"
        );
    }

    function calculateCurrentPrice()
        internal
        view
        returns (uint256 price0, uint256 price1)
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        price0 = reserve0 > 0
            ? (reserve1 * uint256(UQ112x112.Q112)) / reserve0
            : 0;
        price1 = reserve1 > 0
            ? (reserve0 * uint256(UQ112x112.Q112)) / reserve1
            : 0;
    }

    function assertBlockTimestampLast(uint32 expected) internal {
        (, , uint32 blockTimestampLast) = pair.getReserves();

        assertEq(blockTimestampLast, expected, "unexpected blockTimestampLast");
    }


    //  开始讲Liquidity
    function testMintBootstrap() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        assertEq(token0.balanceOf(address(this)), 9 ether);
        assertEq(token1.balanceOf(address(this)), 9 ether);
        // emit Log("before mint",2);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    event checkBlockTimestampe(uint256 blockTimestamp);
    function testMintWhenTheresLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

    
        //设置 block.timestamp
        emit checkBlockTimestampe(block.timestamp);
        assertEq(block.timestamp, 1, "Assert TimeStamp Should be 1");
        vm.warp(37);
        emit checkBlockTimestampe(block.timestamp);
        assertEq(block.timestamp, 37, "Assert TimeStamp Should be 37");
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(address(this)); // + 2 LP

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    event checkEncodeError(bytes encodedError);
    function testMintLiquidityUnderflow() public {
        // 0x11: If an arithmetic operation results in underflow or overflow outside of an unchecked { ... } block.
        // solidity规定的, 算术错误报错0x11
        // Panic 大小写敏感
        emit checkEncodeError(encodeError("Panic(uint256)", 0x11));
        vm.expectRevert(encodeError("Panic(uint256)", 0x11));
        pair.mint(address(this));
    }

    function testMintZeroLiquidity() public {
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1000);

        vm.expectRevert(encodeError("InsufficientLiquidityMinted()"));
        pair.mint(address(this));
    }

    // event checkLiquidity(uint256 liquidity);
    function testBurn() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        uint256 liquidity = pair.balanceOf(address(this));
        uint256 liquidityNull = pair.balanceOf(address(0));
        // emit checkLiquidity(liquidity);
        // emit checkLiquidity(liquidityNull);
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        // Pair的这1000 在谁手里? pair的这1000 是 在全0地址手里的
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
        // assertEq(pair.balanceOf(address(pair)),1000,"Pair Amount Not Right");
    }


    // burn的确是把pair的这代币对 发送到了0地址, 但是但是 这一部分代币对, 就不属于重量了, 即checkBalance 只有最开始来的1000
    // 这个是自己的池子, 自己不平衡, 最后剩下的都留在了池子里
    // 1000000000000000384.0000 如果再来一个外来者 1:1 --> 1 . 再出来的时候, 那就是多出来384
    // event checkLiquidity(uint256 liquidity);
    function testBurnUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        // emit checkLiquidity(pair.balanceOf(address(0)));

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        // emit checkLiquidity(pair.balanceOf(address(0)));

        uint256 liquidity = pair.balanceOf(address(this));
        assertEq(liquidity, 2 ether - 1000, "Liquidity Amount is not Right");
        pair.transfer(address(pair), liquidity);
        // emit checkLiquidity(pair.balanceOf(address(pair)));
        pair.burn(address(this));
        // emit checkLiquidity(pair.balanceOf(address(pair)));
        // emit checkLiquidity(pair.balanceOf(address(0)));

        assertEq(pair.balanceOf(address(this)), 0);
        // 没
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    // event checkLiquidity(uint256 liquidity);
    function testBurnUnbalancedDifferentUsers() public {
        testUser.provideLiquidity(
            address(pair),
            address(token0),
            address(token1),
            1 ether,
            1 ether
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(testUser)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        uint256 liquidity = pair.balanceOf(address(this));
        assertEq(pair.totalSupply(), 2 ether , "Pair Total Supply");
        assertEq(liquidity, 1 ether, "Admin User Liquidity Amount");
        // emit checkLiquidity(liquidity);
        // emit checkLiquidity(pair.totalSupply());

        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));
        // emit checkLiquidity(pair.totalSupply());

        // this user is penalized for providing unbalanced liquidity
        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);

        testUser.removeLiquidity(address(pair));

        // testUser receives the amount collected from this user
        assertEq(pair.balanceOf(address(testUser)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(
            token0.balanceOf(address(testUser)),
            10 ether + 0.5 ether - 1500
        );
        assertEq(token1.balanceOf(address(testUser)), 10 ether - 1000);

        // 上面给出的这个例子 属于A的池子, B来不平衡的添加, B撤出, A再撤出, A撤出的时候 会把B不平衡的Token分走一部分
        // 那如果 A先撤走最后的效果是一样的
    }

    function testBurnZeroTotalSupply() public {
        // 0x12; If you divide or modulo by zero.
        // Mint 0x11
        vm.expectRevert(encodeError("Panic(uint256)", 0x12));
        pair.burn(address(this));
    }

    event checkAddress(address user);
    function testBurnZeroLiquidity() public {
        // Transfer and mint as a normal user.
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));
        // emit checkAddress(address(this));
        // emit checkAddress(address(pair));

        // vm.prank(address(0xdeadbeef));
        // emit checkAddress(msg.sender);
        // emit checkAddress(address(0xdeadbeef));

        vm.expectRevert(encodeError("InsufficientLiquidityBurned()"));
        pair.burn(address(this));
    }

    // 卡住1
    // skip了, 由于slot的问题
    function testReservesPacking() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        bytes32 val = vm.load(address(pair), bytes32(uint256(8)));
        assertEq(
            val,
            hex"000000010000000000001bc16d674ec800000000000000000de0b6b3a7640000"
        );
    }



    // 开始讲Swap
    // event checkLiquidity(uint256 liquidity);
    function testSwapBasicScenario() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));
        // emit checkLiquidity(pair.balanceOf(address(this)));


        // uint256 amountOut = 0.181322178776029826 ether;
        uint256 amountOut = 0.18 ether;
        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, amountOut, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether + amountOut,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.1 ether, uint112(2 ether - amountOut));
    }

    function testSwapBasicScenarioReverseDirection() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether + 0.09 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether - 0.2 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether - 0.09 ether, 2 ether + 0.2 ether);
    }

    // 这个是双向的, 即两个进去 两个出来 问题不大 
    function testSwapBidirectional() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0.18 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.01 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether - 0.02 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.01 ether, 2 ether + 0.02 ether);
    }

    function testSwapZeroOut() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(encodeError("InsufficientOutputAmount()"));
        pair.swap(0, 0, address(this), "");
    }

    function testSwapInsufficientLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        pair.swap(0, 2.1 ether, address(this), "");

        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        pair.swap(1.1 ether, 0, address(this), "");
    }

    function testSwapUnderpriced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.09 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether + 0.09 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.1 ether, 2 ether - 0.09 ether);
    }

    function testSwapOverpriced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        vm.expectRevert(encodeError("InvalidK()"));
        pair.swap(0, 0.36 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether, 2 ether);
        assertEq(token0.balanceOf(address(pair)), 1.1 ether, "Pari Token 0 Balance");
    }

    function testSwapUnpaidFee() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        // 181322178776029827 就会超出
        // 181322178776029826 就会符合要求
        vm.expectRevert(encodeError("InvalidK()"));
        pair.swap(0, 0.181322178776029827 ether, address(this), "");
    }


    // 开始讲Price
    // event checkPrice(uint256 price);
    function testCumulativePrices() public {
        vm.warp(0);
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        (
            uint256 initialPrice0,
            uint256 initialPrice1
        ) = calculateCurrentPrice();

        // 这里其实并不是1, 因为有UQ112x112.Q112=2**112 这个数字的存在
        // emit checkPrice(initialPrice0);
        // emit checkPrice(initialPrice1);

        // 0 seconds passed.
        // 其实这个pair有没有 都 ok
        pair.sync();
        // 这里的block.timestamp = 0 所以两个价格都是0
        assertCumulativePrices(0, 0);

        // 1 second passed.
        vm.warp(1);
        pair.sync();
        assertBlockTimestampLast(1);
        assertCumulativePrices(initialPrice0, initialPrice1);

        // 2 seconds passed.
        vm.warp(2);
        pair.sync();
        assertBlockTimestampLast(2);
        assertCumulativePrices(initialPrice0 * 2, initialPrice1 * 2);

        // 3 seconds passed.
        vm.warp(3);
        pair.sync();
        assertBlockTimestampLast(3);
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);

        // // Price changed.
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));
        // (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // emit checkPrice(uint256(reserve0));
        // emit checkPrice(uint256(reserve1));

        (uint256 newPrice0, uint256 newPrice1) = calculateCurrentPrice();
        // 价格之所以不太对, 不是2/3和3/2, 是因为有UQ112x112.Q112=2**112 这个数字的存在

        // emit checkPrice(newPrice0);
        // emit checkPrice(newPrice1);

        // // 0 seconds since last reserves update.
        // 之所以这里不动, 是因为 timeElapsed = 0会保持原样
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);

        // // 1 second passed.
        vm.warp(4);
        // 如果不sync的话, 是没有update的
        pair.sync();
        assertBlockTimestampLast(4);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0,
            initialPrice1 * 3 + newPrice1
        );

        // 2 seconds passed.
        vm.warp(5);
        pair.sync();
        assertBlockTimestampLast(5);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0 * 2,
            initialPrice1 * 3 + newPrice1 * 2
        );

        // 3 seconds passed.
        vm.warp(6);
        pair.sync();
        assertBlockTimestampLast(6);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0 * 3,
            initialPrice1 * 3 + newPrice1 * 3
        );
    }


    // 整个的流程是, 钱到了flashloan的合约中, 然后又到了池子中, 没有走用户这边
    event checkAddress(string info, address checkAddress);
    event checkAmount(string info, uint256 amount);
    function testFlashloan() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        //
        uint256 flashloanAmount = 0.1 ether;
        // 还必须有最后的+1 不然数量对不上
        uint256 flashloanFee = (flashloanAmount * 1000) / 997 - flashloanAmount + 1;

        // 这样的话 数值还是少一点点
        // uint256 flashloanFee = flashloanAmount * 3 / 1000 + 1;
        
        // emit checkAmount("FlashLoanFee", flashloanFee);
        Flashloaner fl = new Flashloaner();
        // emit checkAddress("Pair Address", address(pair));
        // emit checkAddress("Token0 Address", address(token0));
        // emit checkAddress("Token1 Address", address(token1));
        // emit checkAddress("Self Address", address(this));

        token1.transfer(address(fl), flashloanFee);

        fl.flashloan(address(pair), 0, flashloanAmount, address(token1));

        assertEq(token1.balanceOf(address(fl)), 0);
        assertEq(token1.balanceOf(address(pair)), 2 ether + flashloanFee);
    }
}

contract TestUser {
    function provideLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);

        ZuniswapV2Pair(pairAddress_).mint(address(this));
    }

    function removeLiquidity(address pairAddress_) public {
        uint256 liquidity = ERC20(pairAddress_).balanceOf(address(this));
        ERC20(pairAddress_).transfer(pairAddress_, liquidity);
        ZuniswapV2Pair(pairAddress_).burn(address(this));
    }
}

contract Flashloaner {
    error InsufficientFlashLoanAmount();

    uint256 expectedLoanAmount;

    function flashloan(
        address pairAddress,
        uint256 amount0Out,
        uint256 amount1Out,
        address tokenAddress
    ) public {
        if (amount0Out > 0) {
            expectedLoanAmount = amount0Out;
        }
        if (amount1Out > 0) {
            expectedLoanAmount = amount1Out;
        }

        ZuniswapV2Pair(pairAddress).swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(tokenAddress)
        );
    }

    event checkAddress(string info, address checkAddress);
    event checkAmount(string info, uint256 amount);

    function zuniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) public {
        address tokenAddress = abi.decode(data, (address));
        uint256 balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance < expectedLoanAmount) revert InsufficientFlashLoanAmount();
        // 这个是pair的address
        // emit checkAddress("FlashLoan Check Address msg.sender", msg.sender);
        // 这个是flashloan的address, 注意传参 是pair传过来的, 而是flashloan调用的pair的swap function
        // emit checkAddress("FlashLoan Check Address Sender", sender);
        // emit checkAmount("FlashLoan Check Balance Amount", balance);
        // emit checkAmount("FlashLoan Check Expected Amount", expectedLoanAmount);
        // 因为 balance1Adjust这里的值 由于 amount1In改了, 所以不能只借多少换多少 Fee在这里起作用了

        ERC20(tokenAddress).transfer(msg.sender, balance);
    }
}

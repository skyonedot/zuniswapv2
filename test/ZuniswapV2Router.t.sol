// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/ZuniswapV2Factory.sol";
import "../src/ZuniswapV2Pair.sol";
import "../src/ZuniswapV2Router.sol";
import "./mocks/ERC20Mintable.sol";

contract ZuniswapV2RouterTest is Test {
    ZuniswapV2Factory factory;
    ZuniswapV2Router router;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    ERC20Mintable tokenC;

    function setUp() public {
        factory = new ZuniswapV2Factory();
        router = new ZuniswapV2Router(address(factory));

        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");
        tokenC = new ERC20Mintable("Token C", "TKNC");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
        tokenC.mint(20 ether, address(this));
    }
    event checkAddress(string info, address addr);

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }
    // // 开始Add Liquidity
    // function testAddLiquidityCreatesPair() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));
    //     // emit checkAddress("TestAddLiquidityCreatesPair Pair Address", pairAddress);
    //     // assertEq(pairAddress, 0x28D60B002aE759608479991e780DD542C929539D);
    //     assertEq(pairAddress, 0x4bc0cdA621ba854Eb082BC754ce544EF88f5A233);
    // }

    // function testAddLiquidityNoPair() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     (uint256 amountA, uint256 amountB, uint256 liquidity) = router
    //         .addLiquidity(
    //             address(tokenA),
    //             address(tokenB),
    //             1 ether,
    //             1 ether,
    //             1 ether,
    //             1 ether,
    //             address(this)
    //         );

    //     assertEq(amountA, 1 ether);
    //     assertEq(amountB, 1 ether);
    //     assertEq(liquidity, 1 ether - 1000);

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));

    //     assertEq(tokenA.balanceOf(pairAddress), 1 ether);
    //     assertEq(tokenB.balanceOf(pairAddress), 1 ether);

    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);

    //     // emit checkAddress("TokenA Address", address(tokenA));
    //     // emit checkAddress("TokenB Address", address(tokenB));
    //     // 这里两个Token 谁的Address小, 谁在前面, B的确更小
    //     assertEq(pair.token0(), address(tokenB));
    //     assertEq(pair.token1(), address(tokenA));
    //     assertEq(pair.totalSupply(), 1 ether);
    //     assertEq(pair.balanceOf(address(this)), 1 ether - 1000);

    //     assertEq(tokenA.balanceOf(address(this)), 19 ether);
    //     assertEq(tokenB.balanceOf(address(this)), 19 ether);
    // }

    // function testAddLiquidityAmountBOptimalIsOk() public {
    //     address pairAddress = factory.createPair(
    //         address(tokenA),
    //         address(tokenB)
    //     );

    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);

    //     assertEq(pair.token0(), address(tokenB));
    //     assertEq(pair.token1(), address(tokenA));

    //     tokenA.transfer(pairAddress, 1 ether);
    //     tokenB.transfer(pairAddress, 2 ether);
    //     pair.mint(address(this));

    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 2 ether);

    //     // 最后出来的是1:2
    //     // 这样想, 1.9 只需0.95, 但是1需要2, 所以是1:2
    //     (uint256 amountA, uint256 amountB, uint256 liquidity) = router
    //         .addLiquidity(
    //             address(tokenA),
    //             address(tokenB),
    //             1 ether,
    //             2 ether,
    //             1 ether,
    //             1.9 ether,
    //             address(this)
    //         );

    //     assertEq(amountA, 1 ether);
    //     assertEq(amountB, 2 ether);
    //     assertEq(liquidity, 1414213562373095048);
    // }

    // function testAddLiquidityAmountBOptimalIsTooLow() public {
    //     address pairAddress = factory.createPair(
    //         address(tokenA),
    //         address(tokenB)
    //     );

    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);
    //     assertEq(pair.token0(), address(tokenB));
    //     assertEq(pair.token1(), address(tokenA));

    //     tokenA.transfer(pairAddress, 5 ether);
    //     tokenB.transfer(pairAddress, 10 ether);
    //     pair.mint(address(this));

    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 2 ether);

    //     vm.expectRevert(encodeError("InsufficientBAmount()"));
    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         2 ether,
    //         1 ether,
    //         2 ether,
    //         address(this)
    //     );
    //     //  其实之所以会报错 是这句话 if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
    //     //  而上面不报错是因为第一次添加流动性, 而这里不是第一次添加  把等于号去掉, 就是很正常的
    //     // (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
    //     //     address(tokenA),
    //     //     address(tokenB),
    //     //     1 ether,
    //     //     2 ether,
    //     //     1 ether,
    //     //     2 ether,
    //     //     address(this)
    //     // );
    //     // assertEq(amountA, 1 ether);
    //     // assertEq(amountB, 2 ether);
    //     // assertEq(liquidity, 1414213562373095048);
    // }

    // function testAddLiquidityAmountBOptimalTooHighAmountATooLow() public {
    //     address pairAddress = factory.createPair(
    //         address(tokenA),
    //         address(tokenB)
    //     );
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);

    //     assertEq(pair.token0(), address(tokenB));
    //     assertEq(pair.token1(), address(tokenA));

    //     tokenA.transfer(pairAddress, 10 ether);
    //     tokenB.transfer(pairAddress, 5 ether);
    //     pair.mint(address(this));

    //     tokenA.approve(address(router), 2 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     // 的确会报错, 但是我感觉 可能报错的error这里有点问题? 并不是amount不够啊. 可能语义上的差别
    //     vm.expectRevert(encodeError("InsufficientAAmount()"));
    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         2 ether,
    //         0.9 ether,
    //         2 ether,
    //         1 ether,
    //         address(this)
    //     );
    // }

    // function testAddLiquidityAmountBOptimalIsTooHighAmountAOk() public {
    //     address pairAddress = factory.createPair(
    //         address(tokenA),
    //         address(tokenB)
    //     );
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);

    //     assertEq(pair.token0(), address(tokenB));
    //     assertEq(pair.token1(), address(tokenA));

    //     tokenA.transfer(pairAddress, 10 ether);
    //     tokenB.transfer(pairAddress, 5 ether);
    //     pair.mint(address(this));

    //     tokenA.approve(address(router), 2 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     (uint256 amountA, uint256 amountB, uint256 liquidity) = router
    //         .addLiquidity(
    //             address(tokenA),
    //             address(tokenB),
    //             2 ether,
    //             0.9 ether,
    //             1.7 ether,
    //             1 ether,
    //             address(this)
    //         );
    //     assertEq(amountA, 1.8 ether);
    //     assertEq(amountB, 0.9 ether);
    //     assertEq(liquidity, 1272792206135785543);
    // }

    // // 开始RemoveLiquidity
    // function testRemoveLiquidity() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);
    //     uint256 liquidity = pair.balanceOf(address(this));
    //     assertEq(liquidity, 1 ether-1000, "Liquidity Amount Check");

    //     pair.approve(address(router), liquidity);

    //     router.removeLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         liquidity,
    //         1 ether - 1000,
    //         1 ether - 1000,
    //         address(this)
    //     );

    //     (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
    //     assertEq(reserve0, 1000);
    //     assertEq(reserve1, 1000);
    //     assertEq(pair.balanceOf(address(this)), 0);
    //     assertEq(pair.totalSupply(), 1000);
    //     assertEq(tokenA.balanceOf(address(this)), 20 ether - 1000);
    //     assertEq(tokenB.balanceOf(address(this)), 20 ether - 1000);
    // }

    // // 其实这些 700, 300 看着很麻烦, 但是用数学公式推一推 不难
    // function testRemoveLiquidityPartially() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);
    //     uint256 liquidity = pair.balanceOf(address(this));

    //     liquidity = (liquidity * 3) / 10;
    //     pair.approve(address(router), liquidity);

    //     router.removeLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         liquidity,
    //         0.3 ether - 300,
    //         0.3 ether - 300,
    //         address(this)
    //     );

    //     (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
    //     assertEq(reserve0, 0.7 ether + 300);
    //     assertEq(reserve1, 0.7 ether + 300);
    //     assertEq(pair.balanceOf(address(this)), 0.7 ether - 700);
    //     assertEq(pair.totalSupply(), 0.7 ether + 300);
    //     assertEq(tokenA.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
    //     assertEq(tokenB.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
    // }

    // function testRemoveLiquidityInsufficientAAmount() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);
    //     uint256 liquidity = pair.balanceOf(address(this));

    //     pair.approve(address(router), liquidity);

    //     vm.expectRevert(encodeError("InsufficientAAmount()"));
    //     router.removeLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         liquidity,
    //         1 ether,
    //         1 ether - 1000,
    //         address(this)
    //     );
    // }

    // function testRemoveLiquidityInsufficientBAmount() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address pairAddress = factory.pairs(address(tokenA), address(tokenB));
    //     ZuniswapV2Pair pair = ZuniswapV2Pair(pairAddress);
    //     uint256 liquidity = pair.balanceOf(address(this));

    //     pair.approve(address(router), liquidity);

    //     vm.expectRevert(encodeError("InsufficientBAmount()"));
    //     router.removeLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         liquidity,
    //         1 ether - 1000,
    //         1 ether,
    //         address(this)
    //     );
    // }

    // // getAmountsOut,给定输入 求输出
    // function testSwapExactTokensForTokens() public {
    //     tokenA.approve(address(router), 1 ether);
    //     tokenB.approve(address(router), 2 ether);
    //     tokenC.approve(address(router), 1 ether);

    //     router.addLiquidity(
    //         address(tokenA),
    //         address(tokenB),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     router.addLiquidity(
    //         address(tokenB),
    //         address(tokenC),
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         1 ether,
    //         address(this)
    //     );

    //     address[] memory path = new address[](3);
    //     path[0] = address(tokenA);
    //     path[1] = address(tokenB);
    //     path[2] = address(tokenC);

    //     tokenA.approve(address(router), 0.3 ether);
    //     // amounts = [0.3, 0.23023631745054265, 0.18669141421973426 ]
    //     // 其实按照path 计算出 amounts之后, 真实转账在pair的swap那里的check 肯定会过
    //     router.swapExactTokensForTokens(
    //         0.3 ether,
    //         0.1 ether,
    //         path,
    //         address(this)
    //     );

    //     // Swap 0.3 TKNA for ~0.186 TKNB
    //     assertEq(
    //         tokenA.balanceOf(address(this)),
    //         20 ether - 1 ether - 0.3 ether
    //     );
    //     assertEq(tokenB.balanceOf(address(this)), 20 ether - 2 ether);
    //     assertEq(
    //         tokenC.balanceOf(address(this)),
    //         20 ether - 1 ether + 0.186691414219734305 ether
    //     );
    // }


    // 给定输出 求输入 和上面反着来就好
    function testSwapTokensForExactTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapTokensForExactTokens(
            0.186691414219734305 ether,
            0.3 ether,
            path,
            address(this)
        );
        // Swap 0.3 TKNA for ~0.186 TKNB
        assertEq(
            tokenA.balanceOf(address(this)),
            20 ether - 1 ether - 0.3 ether
        );
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 2 ether);
        assertEq(
            tokenC.balanceOf(address(this)),
            20 ether - 1 ether + 0.186691414219734305 ether
        );
    }
}

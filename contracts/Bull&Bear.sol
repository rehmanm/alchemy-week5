// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint public /*immutable */ interval;
    uint public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

        // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];

    event TokensUpdated(string marketTrend);

    constructor(uint _updateInterval, address _priceFeed) ERC721("Bull&Bear", "BBTK") {
        //Sets keeper update data
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;

        //set the price feed address to
        // BTC / USD price Feed Contract Address on Rinkeby: https://rinkeby.etherscan.io/address/0xECe365B379E1dD183B20fc5f022230C044d51404
        // or the MockPriceFeed Contract
        // source of above address: https://docs.chain.link/docs/ethereum-addresses/
        priceFeed = AggregatorV3Interface(_priceFeed);
        currentPrice = getLatestPrice();

    }



    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        //Defaults to gamer bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
        
    }

    //https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/

    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        console.log( block.timestamp, lastTimeStamp, interval, block.timestamp - lastTimeStamp);
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        console.log( block.timestamp, lastTimeStamp, interval, block.timestamp - lastTimeStamp);
        if((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if (latestPrice == currentPrice) {
                return;
            }
            if (latestPrice < currentPrice) {
                //bear
                updateAllTokenUris("bear");
            } else {
                //bull
                updateAllTokenUris("bull");
            }

            currentPrice = latestPrice;
            
        } else {
            console.log("Interval not completed yet");
        }
    }

    //https://docs.chain.link/docs/price-feeds-api-reference/
    //https://docs.chain.link/docs/get-the-latest-price/
    function getLatestPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //price will return with 8 decimal place
        return price; //example price returned 3034715771688
    }
    
    function updateAllTokenUris(string memory trend) internal {
        if (compareStrings(trend, "bear")) {
            for (uint i =0; i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, bearUrisIpfs[i]);
            }
        } else {
            for (uint i =0; i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, bullUrisIpfs[i]);
            }
        }
        
        emit TokensUpdated(trend);
    }

    function setInterval(uint256 _newInterval) public onlyOwner {
        interval = _newInterval;
    }

    function setPriceFeedAddress(address _newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_newFeed);
    }

    //Helpers
    function compareStrings(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
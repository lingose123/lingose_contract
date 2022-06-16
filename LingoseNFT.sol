/*
    Copyright 2022 Project Lingose.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/


pragma solidity 0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ILingoseNFT.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/cryptography/ECDSA.sol";


contract LingoseNFT is ERC721, ILingoseNFT, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address public signer = 0x86a7b3bc5a446A7C5ad84ACC73fd2E24d8bed8eE;

    address public result;

    address public contractAddress = 0xe1cB316f4c445C50F430F96c9111f77BfB6c2775;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event EventMinterAdded(address indexed newMinter);
    event EventMinterRemoved(address indexed oldMinter);



    /**
     * Only minter.
     */
    modifier onlyMinter() {
        require(minters[msg.sender], "must be minter");
        _;
    }

    /* ============ Enums ================ */
    /* ============ Structs ============ */
    /* ============ State Variables ============ */

    // Mint and burn star.
    mapping(address => bool) public minters;

     mapping(address => bool) public minteders;
    // Default allow transfer
    bool public transferable = false;

    uint256 public reward=10000000000000000000;


    bool public contractable = true;

    uint256 public  startTime;
    uint256 public  endTime;


    // Star id to cid.
    mapping(uint256 => uint256) private _cids;

    uint256 private _starCount;
    string private _LingoseName;
    string private _lingoseSymbol;

    /* ============ Constructor ============ */
    // constructor()  ERC721("LingoseNFT", "Lingose") {}
    constructor()  ERC721("Cyball","Cyball") {
           // _setBaseURI("https://newart/nft/");    
    }

function _verify(bytes32 dataHash, bytes memory signature, address account) private pure returns (bool) {

	return dataHash.toEthSignedMessageHash().recover(signature) == account;
}

function pubVerify(bytes memory signature, bytes32 msgHash) public view returns (bool) {
	bool r = _verify(msgHash, signature, signer);
	return r;
}


  function toGetSignedMessageHash(address account,string memory taskId) public  pure returns (bytes32) {

    //  return   keccak256(abi.encode(account));
	return keccak256(abi.encodePacked(toString(account,taskId)));
}
 


function toString(address account,string memory taskId) public pure returns(string memory) {
    return toString(abi.encodePacked(account,taskId));
}

function toString(bytes memory data) public pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _lingoseName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _lingoseSymbol;
    }



    /**
     * @dev Get Lingose NFT CID
     */
    function cid(uint256 tokenId) public view returns (uint256) {
        return _cids[tokenId];
    }

    /* ============ External Functions ============ */
    function mint(address account, uint256 cid1)
        external
        override
        onlyMinter
        returns (uint256)
    {
        _starCount++;
        uint256 sID = _starCount;

        _mint(account, sID);
        _cids[sID] = cid1;
        return sID;
    }


    function holdmint(address account, uint256 cid1,bytes memory signature,string memory taskId) external returns (uint256)
    {
        require(!minteders[account], "already minted");

        require(contractable, "contract disable");

        require(startTime < block.timestamp,"startime must lt now");
        
        require(endTime > block.timestamp,"_endtime must gt now");

        require(pubVerify(signature,toGetSignedMessageHash(account,taskId)), "pubVerify error");
        
        _starCount++;
        uint256 sID = _starCount;

        _mint(account, sID);
     
        // _safeTransfer(contractAddress, account,reward);

         minteders[account] = true;
        _cids[sID] = cid1;
        return sID;
    }


 function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
    

    function mintBatch(
        address account,
        uint256 amount,
        uint256[] calldata cidArr
    ) external override onlyMinter returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](amount);
        for (uint256 i = 0; i < ids.length; i++) {
            _starCount++;
            ids[i] = _starCount;
            _mint(account, ids[i]);
            _cids[ids[i]] = cidArr[i];
        }
        return ids;
    }

    function burn(address account, uint256 id) external override onlyMinter {
        require(
            _isApprovedOrOwner(_msgSender(), id),
            "ERC721: caller is not approved or owner"
        );
        _burn(id);
        delete _cids[id];
    }

    function burnBatch(address account, uint256[] calldata ids)
        external
        override
        onlyMinter
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), ids[i]),
                "ERC721: caller is not approved or owner"
            );
            _burn(ids[i]);
            delete _cids[ids[i]];
        }
    }

    /* ============ External Getter Functions ============ */
    function isOwnerOf(address account, uint256 id)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
    }

    function getNumMinted() external view override returns (uint256) {
        return _starCount;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id <= _starCount, "NFT does not exist");
        if (bytes(baseURI()).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(baseURI(), uint2str(id), ".json"));
        }
    }

    /* ============ Internal Functions ============ */
    /* ============ Private Functions ============ */
    /* ============ Util Functions ============ */
    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new baseURI for all token types.
     */
    function setURI(string memory newURI) external onlyOwner {
        _setBaseURI(newURI);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new transferable for all token types.
     */
    function setTransferable(bool _transferable) external onlyOwner {
        transferable = _transferable;
    }

     function setContractTime(uint256  newStrat,uint256  newEnd) external onlyOwner {
        startTime=newStrat;
        endTime=newEnd;
    }

      function setContractable(bool _contractable) external onlyOwner {
        contractable = _contractable;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new name for all token types.
     */
    function setName(string memory _name) external onlyOwner {
        _lingoseName = _name;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new symbol for all token types.
     */
    function setSymbol(string memory _symbol) external onlyOwner {
        _lingoseSymbol = _symbol;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Add a new minter.
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "Minter must not be null address");
        require(!minters[minter], "Minter already added");
        minters[minter] = true;
        emit EventMinterAdded(minter);
    }


        /**
     * @dev Whitelists a bunch of addresses.
     * @param _whitelistees address[] of addresses to whitelist.
     */
    function addWhitelist(address[] memory _whitelistees) public onlyOwner {
      // Add all whitelistees.
      for (uint256 i = 0; i < _whitelistees.length; i++) {
        address creator = _whitelistees[i];
        if (!minters[creator]) {
           minters[creator] = true;
        }
      }
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Remove a old minter.
     */
    function removeMinter(address minter) external onlyOwner {
        require(minters[minter], "Minter does not exist");
        delete minters[minter];
        emit EventMinterRemoved(minter);
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployBasicNft} from "../../script/DeployBasicNft.s.sol";
import {BasicNft} from "../../src/BasicNft.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";

contract BasicNftTest is StdInvariant, Test {
    BasicNft public basicNft;
    DeployBasicNft public deployer;
    string public constant PUG_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    address public USER = makeAddr("user");
    FuzzSelector public newTargetedSelector_;

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = BasicNft.mintNft.selector;
        newTargetedSelector_ = FuzzSelector(address(basicNft), selectors);
        targetSelector(newTargetedSelector_);
        targetSender(USER);
    }

    function testMintingGoingRightUsingContract() public {
        vm.prank(address(basicNft));
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(address(basicNft)) == 1);
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Dogie";
        string memory actualName = basicNft.name();
        assert(
            keccak256(abi.encodePacked(expectedName)) ==
                keccak256(abi.encodePacked(actualName))
        );
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assert(basicNft.balanceOf(USER) == 1);
        assert(
            keccak256(abi.encodePacked(PUG_URI)) ==
                keccak256(abi.encodePacked(basicNft.tokenURI(0)))
        );
    }

    function testCanTransferNft() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        vm.prank(USER);
        basicNft.approve(address(basicNft), 0);
        vm.prank(USER);
        basicNft.transferFrom(USER, address(basicNft), 0);
        assert(basicNft.balanceOf(USER) == 0);
        assert(basicNft.balanceOf(address(basicNft)) == 1);
    }

    function testInteractions() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        basicNft.burnNft(0);
        assert(basicNft.balanceOf(USER) == 0);
        assert(
            keccak256(abi.encodePacked(basicNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(""))
        );
    }

    function testFuzzMintNft(string memory tokenUri) public {
        vm.prank(USER);
        basicNft.mintNft(tokenUri);
        assert(basicNft.balanceOf(USER) == 1);
    }

    function invariant_testMintNft() public view {
        uint256 depth = 15;
        assert(basicNft.balanceOf(USER) < depth); // depth is 15 (foundry.toml)
    }
}

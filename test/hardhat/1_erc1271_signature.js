// test/signature-test.js

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256, toUtf8Bytes } = ethers.utils;

describe("SmartContractWallet Signature on Mumbai Testnet", function () {
    let Factory, SmartContractWallet, factory, smartContractWallet, owner, addr1;
    let message = "Hello, World!";
    let messageHash = keccak256(toUtf8Bytes(message));

    before(async function () {
        [owner, addr1] = await ethers.getSigners();
        Factory = await ethers.getContractFactory("Factory");
        SmartContractWallet = await ethers.getContractFactory("SmartContractWallet");
        factory = await Factory.deploy();
        await factory.deployed();
    });

    it("Should deploy a new SmartContractWallet from Factory", async function () {
        const tx = await factory.createWallet(owner.address);
        const receipt = await tx.wait();
        const walletAddress = receipt.events[0].args[0];
        smartContractWallet = SmartContractWallet.attach(walletAddress);
        expect(await smartContractWallet.owner()).to.equal(owner.address);
    });

    it("Should generate and verify owner's signature", async function () {
        const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
        const isValid = await smartContractWallet.isValidSignature(messageHash, signature);
        expect(isValid).to.equal("0x1626ba7e");
    });

    it("Should fail to verify non-owner's signature", async function () {
        const signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));
        const isValid = await smartContractWallet.isValidSignature(messageHash, signature);
        expect(isValid).to.not.equal("0x1626ba7e");
    });
});

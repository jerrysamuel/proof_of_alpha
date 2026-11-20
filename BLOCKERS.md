# Blockers and unverified items

- UNVERIFIED: The configured GitHub remote is empty, so README commands could not be verified from a true clean clone. Local dependency installation and all runnable README verification commands were run in the working tree.
- HUMAN ACTION: Supply and verify the real Agent ID and Chainlink feed addresses for the target network. The fork test skips cleanly when `RPC_URL` and `CHAINLINK_FEED_ADDRESS` are absent.
- HUMAN ACTION: Complete an independent contract/security review before deployment.
- HUMAN ACTION: Verify deployment, source verification, multisig ownership, hackathon policy, and resolver key custody on the target network.

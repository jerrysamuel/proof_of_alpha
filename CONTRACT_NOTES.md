# Contract notes

- Baseline contract intentionally records the latest oracle price at posting; a v2 could lock entry to the first round after posting.
- The supplied design relies on a caller-provided first round at or after expiry and validates the previous round; this should receive a second-person review before deployment.

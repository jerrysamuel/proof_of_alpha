#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")" && pwd)"
source="$root/src/ProofOfAlpha.sol"
backup="$(mktemp)"
cp "$source" "$backup"
restore() { cp "$backup" "$source"; rm -f "$backup"; }
trap restore EXIT

mutate_and_expect_failure() {
  local name="$1" needle="$2" test_name="$3"
  python3 - "$source" "$needle" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
needle = sys.argv[2].replace('\\n', '\n')
text = path.read_text()
if needle not in text:
    raise SystemExit(f'mutation target not found: {needle}')
path.write_text(text.replace(needle, 'if (false) {}', 1))
PY
  if forge test --match-test "$test_name" >/tmp/poa-mutation-output 2>&1; then
    echo "MUTATION FAILED TO BREAK TEST: $name"
    cat /tmp/poa-mutation-output
    exit 1
  fi
  echo "MUTATION CAUGHT: $name"
  cp "$backup" "$source"
}

mutate_and_expect_failure "Agent ID gate" "if (agentId.balanceOf(msg.sender) == 0) revert NotAgentID();" "testOnlyAgentCanPost"
mutate_and_expect_failure "duration bounds" "if (duration < MIN_DURATION || duration > MAX_DURATION) revert BadDuration();" "testBadDurationsAndPricesRevert"
mutate_and_expect_failure "staleness and non-positive price" "if (price <= 0 || updatedAt + f.maxStaleness < block.timestamp) revert StalePrice();" "testBadDurationsAndPricesRevert"
mutate_and_expect_failure "open-call cap" "if (s.open >= MAX_OPEN_CALLS) revert TooManyOpenCalls();" "testOpenCallLimit"
mutate_and_expect_failure "first-round check" "if (prevUpdatedAt != 0 && prevUpdatedAt >= c.expiresAt) revert NotFirstRound();" "testResolveGuardsAndFirstRoundRule"
echo "MUTATION CHECK PASSED: all five key rules were test-sensitive and source was restored"

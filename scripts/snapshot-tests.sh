#!/usr/bin/env bash
# Runs the component snapshot tests (Gallery/SnapshotTests) on an iOS Simulator.
#
#   scripts/snapshot-tests.sh            # compare with the references; fail on a difference
#   SNAPSHOT_TESTING_RECORD=all scripts/snapshot-tests.sh   # (re)write every reference
#
# SNAPSHOT_TESTING_RECORD: never (default here) | missing | failed | all.
# SNAPSHOT_ARTIFACTS: where the images of failing snapshots are written (CI uploads them).
# SNAPSHOT_DEVICE: simulator name, "iPhone 17 Pro" by default. References are recorded on
# CI (manual CI run with record_snapshots) with the Xcode pinned in .github/workflows/ci.yml;
# see docs/snapshots.md.
set -euo pipefail

cd "$(dirname "$0")/../Gallery"

RECORD="${SNAPSHOT_TESTING_RECORD:-never}"
ARTIFACTS="${SNAPSHOT_ARTIFACTS:-${TMPDIR:-/tmp}/snapshot-artifacts}"
DEVICE_NAME="${SNAPSHOT_DEVICE:-iPhone 17 Pro}"
mkdir -p "$ARTIFACTS"

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate

# The newest iOS runtime of the selected Xcode, the named iPhone in it (else the first iPhone).
DEVICE=$(xcrun simctl list devices available --json | DEVICE_NAME="$DEVICE_NAME" python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"]
runtimes = sorted((r for r in devices if ".iOS-" in r),
                  key=lambda r: [int(x) for x in r.rsplit(".iOS-", 1)[1].split("-")], reverse=True)
want = os.environ["DEVICE_NAME"]
for runtime in runtimes:
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    if not phones:
        continue
    pick = next((d for d in phones if d["name"] == want), phones[0])
    print(pick["udid"], runtime.rsplit(".", 1)[1], pick["name"], sep="|")
    break
')
DEVICE_ID="${DEVICE%%|*}"
echo "Snapshot device: ${DEVICE#*|} · $(xcodebuild -version | head -1) · record=$RECORD"

set +e
TEST_RUNNER_SNAPSHOT_TESTING_RECORD="$RECORD" \
TEST_RUNNER_SNAPSHOT_ARTIFACTS="$ARTIFACTS" \
xcodebuild test \
  -project Gallery.xcodeproj \
  -scheme Gallery \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath build \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee snapshot-test.log | grep -aE "error:|failed|recorded|Test run with|\*\* TEST (SUCCEEDED|FAILED)"
set -e

grep -aq "\*\* TEST SUCCEEDED \*\*" snapshot-test.log

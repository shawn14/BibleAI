"""Read the real disposable Simulator app's persisted growth state after its UI journey."""
import json
import plistlib
import sys
from pathlib import Path

prefs = plistlib.loads(Path(sys.argv[1]).read_bytes())
state = json.loads(prefs["growth.local.v1"])
counts = state.get("eventTotals", {})
attribution = state.get("attribution", {})
observed = {
    "eventTotals": counts,
    "readerActivated": state.get("readerActivatedAt") is not None,
    "newRecipient": attribution.get("isNewReader"),
    "recipientActivated": attribution.get("activatedAt") is not None,
}
print("GROWTH_PERSISTED " + json.dumps(observed, sort_keys=True))
if sys.argv[2] == "0":
    assert observed["readerActivated"] and observed["newRecipient"] and observed["recipientActivated"], observed
    for key, expected in {"sharePresented": 2, "shareCompleted": 1, "shareCancelled": 1,
                          "invitationOpened": 2, "invitationAccepted": 2, "firstReading": 1}.items():
        assert counts.get(key, 0) == expected, (key, counts)
    assert counts.get("shareFailed", 0) == 0, counts
    print("GROWTH_PERSISTENCE_PASSED")

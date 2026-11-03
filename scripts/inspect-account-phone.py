#!/usr/bin/env python3
"""Read paired iPhone connectivity and only the installed Bright Scroll app metadata.
No install, launch, termination, pairing change or personal app-data access.
Run through the committed mac-run action.
"""
import datetime
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
if not os.environ.get("MAC_RUNNER_JOB_ID"):
    raise SystemExit("Use mac-run BibleAI inspect_account_phone")
targets = json.loads(subprocess.check_output([
    "ruby", "-rxcodeproj", "-rjson", "-e",
    'p=Xcodeproj::Project.open("BibleAI.xcodeproj"); '
    'a=p.targets.select { |t| t.product_type == "com.apple.product-type.application" }; '
    'abort "Expected one app target" unless a.length == 1; '
    'puts JSON.generate(a.first.build_configurations.map { |c| c.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] }.uniq)'
], cwd=ROOT, text=True))
if len(targets) != 1:
    raise SystemExit("Expected one app bundle identifier")
report = {"observedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
          "bundle": targets[0], "devices": [], "scope": "Connectivity and app metadata only; no feature proof"}
with tempfile.TemporaryDirectory(prefix="bible-account-phone-read-") as scratch:
    def query(name, args):
        dest = Path(scratch) / (name + ".json")
        subprocess.run(["xcrun", "devicectl", "--timeout", "30", *args,
                        "--json-output", str(dest)], check=True,
                       stdout=subprocess.DEVNULL, timeout=45)
        return json.loads(dest.read_text())["result"]
    devices = query("devices", ["list", "devices"])["devices"]
    for device in devices:
        props = device.get("deviceProperties", {})
        hardware = device.get("hardwareProperties", {})
        connection = device.get("connectionProperties", {})
        if hardware.get("deviceType") != "iPhone":
            continue
        item = {"name": props.get("name"), "model": hardware.get("marketingName"),
                "pairingState": connection.get("pairingState"),
                "tunnelState": connection.get("tunnelState"),
                "transportType": connection.get("transportType"),
                "osVersion": props.get("osVersionNumber")}
        report["devices"].append(item)
        if connection.get("pairingState") == "paired" and connection.get("tunnelState") == "connected":
            try:
                apps = query("bible", ["device", "info", "apps", "--device", device["identifier"],
                                      "--include-default-apps", "--bundle-id", targets[0]])["apps"]
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                item["bible"] = "Inspection failed; installed version remains unknown"
                report["scope"] = "Partial connectivity result; app query stopped on the first device error"
                print(json.dumps(report, indent=2))
                raise SystemExit("CoreDevice app inspection failed; no retry or device change performed")
            item["bible"] = [{k: app.get(k) for k in ["name", "bundleIdentifier", "version", "bundleVersion", "builtByDeveloper"]}
                            for app in apps]
        else:
            item["bible"] = "Not inspected: no active paired connection"
    print(json.dumps(report, indent=2))

#!/usr/bin/env python3
"""Read existing local development signing support; never creates or changes credentials."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess

if not os.environ.get("MAC_RUNNER_JOB_ID"):
    raise SystemExit("Use mac-run BibleAI inspect_account_signing")
root = Path(__file__).resolve().parents[1]
settings = json.loads(subprocess.check_output([
    "ruby", "-rxcodeproj", "-rjson", "-e",
    'p=Xcodeproj::Project.open("BibleAI.xcodeproj"); '
    'a=p.targets.select { |t| t.product_type == "com.apple.product-type.application" }; '
    'abort "Expected one app target" unless a.length == 1; '
    'puts JSON.generate(a.first.build_configurations.find { |c| c.name == "Debug" }.build_settings)'
], cwd=root, text=True))
team = settings["DEVELOPMENT_TEAM"]
bundle = settings["PRODUCT_BUNDLE_IDENTIFIER"]
identities = subprocess.check_output(["security", "find-identity", "-v", "-p", "codesigning"], text=True)
local = set(re.findall(r"\b[0-9A-F]{40}\b", identities))
profiles = []
for directory in [Path.home()/"Library/MobileDevice/Provisioning Profiles",
                  Path.home()/"Library/Developer/Xcode/UserData/Provisioning Profiles"]:
    for path in directory.glob("*.mobileprovision"):
        try:
            profile = plistlib.loads(subprocess.check_output(
                ["security", "cms", "-D", "-i", str(path)], stderr=subprocess.DEVNULL))
        except (subprocess.CalledProcessError, plistlib.InvalidFileException):
            continue
        e = profile.get("Entitlements", {})
        if team not in profile.get("TeamIdentifier", []):
            continue
        if e.get("application-identifier") != team + "." + bundle:
            continue
        certs = {hashlib.sha1(c).hexdigest().upper() for c in profile.get("DeveloperCertificates", [])}
        profiles.append({"name": profile.get("Name"), "uuid": profile.get("UUID"),
                         "expires": profile["ExpirationDate"].isoformat(),
                         "expired": profile["ExpirationDate"] <= datetime.datetime.utcnow(),
                         "development": e.get("get-task-allow") is True,
                         "matchingLocalIdentity": bool(certs & local),
                         "deviceCount": len(profile.get("ProvisionedDevices", [])),
                         "appleSignIn": e.get("com.apple.developer.applesignin"),
                         "iCloudKV": e.get("com.apple.developer.ubiquity-kvstore-identifier")})
print(json.dumps({"bundle": bundle, "team": team, "localIdentityCount": len(local),
                  "profiles": profiles, "writes": 0}, indent=2))

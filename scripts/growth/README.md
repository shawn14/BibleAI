# Referral cohort report

`referral_report.py` joins explicitly collected `GrowthStore.exportSnapshotData()` exports.
It is the calculation layer for the growth experiment, not a deployed telemetry collector.
There are no observed Bright Scroll user cohorts in this directory.

Wrap each actual export in a collection envelope:

```json
{
  "observedAt": "<actual collection time in ISO8601 with timezone>",
  "snapshot": "<the exported JSON object, not a string>"
}
```

Do not guess collection time from event time or file mtime. Each input is bounded to2MB.
The report rejects timestamps beyond its explicit as-of time, decreasing lifetime counters,
changed first attribution, conflicting event IDs and unsupported schemas. It merges older and
newer exports of the same installation so repeated collection does not double-count and retained
older records can recover events trimmed from the native200-event buffer.

```sh
python3 scripts/growth/referral_report.py \
  --cohort-start 2026-09-01T00:00:00Z \
  --cohort-end 2026-09-02T00:00:00Z \
  --as-of 2026-11-02T09:00:00Z \
  /absolute/path/to/collected-export.json
python3 -m unittest discover -s scripts/growth -p 'test_*.py' -v
```

Choose dates from the actual experiment; the command dates above are format examples only.
The cohort includes every observed installation first activated in[start,end), including
non-sharers. A completed native share activity establishes the observed sender/token mapping;
it does not by itself count as a delivered invitation or a referral. A referred activation
requires another installation, first-touch `isNewReader`, the exact same content, acceptance
before actual reading and a reading within30days of the seed's activation. Repeated shares or
exports do not add another recipient. Ambiguous owners, changed targets, self-referrals and
returning readers do not count. A seed's full30-day observation window is reported separately.

`populationK30` always remains null: selected device exports do not prove population coverage.
`observedReferralsPerEligibleSeed` and `observedReferralsPerMatureSeed` are explicitly sample
ratios. Missing recipient/seed exports, trimmed history, reinstalls and unverified client reports
remain limitations. Output contains aggregate counts only, not installation IDs or verse content.
The14 tests use synthetic arithmetic fixtures; passing them is not evidence of viral growth.

Before this supports a live experiment: implement and verify first-party collection with the
appropriate disclosure/choice, preserve collection timestamps and deduplication, confirm all
eligible seed exposure and recipient coverage, and collect a mature cohort. That work, the
website runtime/deploy and the new native binary remain outstanding.

# First approved Air test — failed before app launch

- Exact input source: `64bb1cf9672f1f4c9844fa4df44d4c6d6f56a2a6`.
- Job: `BibleAI-test_reader-20261028-170359-lflo`, 2026-10-28 17:05:35–17:07:39 CDT.
- Runtime: 123.8 seconds, exit65. This consumes the single authorized Air test run.
- Actual Xcode error: multiple commands produce `-Runner.app/PlugIns/.xctest`.
- Project inspection confirms both UI-test configurations omitted PRODUCT_NAME. The source
  correction sets it to `$(TARGET_NAME)`, matching the app target, and check-source.py guards it.
- No app compilation success, UI assertions, screenshots or provider study was produced.
  The corrected target still requires a newly authorized native run; do not claim it fixed at runtime.
- Owned simulator F1DF7111-32A4-4453-A2F5-4882ADC8ED27 was deleted. Runner is idle.
- Admission receipts prove the exact original Air policy bytes/flags restored immediately after
  job start. The first short admission window missed the runner's60-second polling interval;
  reannouncing the same pending job through WatchPaths started the one actual native execution.

`native.log`, `runner-result.json`, admission receipts and `cleanup.log` are raw local evidence.
The disposable simulator and intermediate build output are not deliverables.

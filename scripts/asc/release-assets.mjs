// 2.0.2 (Shawn 2026-11-03 "push this to the App Store"): upload all screenshots, preview and
// header/search videos from docs/aso onto the new editable version via the shared uploader.
import upload from "./store-assets.mjs";
export default async (api) => upload(api, { guarded: true });

// Minimal App Store Connect API client. Uses the team's API key in ~/.appstoreconnect/private_keys.
// Usage: node scripts/asc/asc.mjs <job.mjs>   (a job exports default async (api) => result)
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const KEY_ID = "6T6GWQ6BW7";
const ISSUER = "69a6de83-d381-47e3-e053-5b8c7c11a4d1";
const key = fs.readFileSync(path.join(os.homedir(), `.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`), "utf8");

function token() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  const data = `${b64({ alg: "ES256", kid: KEY_ID, typ: "JWT" })}.${b64({ iss: ISSUER, iat: now, exp: now + 1100, aud: "appstoreconnect-v1" })}`;
  const sig = crypto.sign("sha256", Buffer.from(data), { key, dsaEncoding: "ieee-p1363" }).toString("base64url");
  return `${data}.${sig}`;
}

async function call(method, url, body) {
  const full = url.startsWith("http") ? url : `https://api.appstoreconnect.apple.com${url}`;
  const res = await fetch(full, {
    method,
    headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json; try { json = text ? JSON.parse(text) : {}; } catch { json = { raw: text }; }
  if (!res.ok) { const e = new Error(`${method} ${url} -> ${res.status}: ${JSON.stringify(json.errors ?? json).slice(0, 800)}`); e.status = res.status; e.json = json; throw e; }
  return json;
}

const api = {
  get: (u) => call("GET", u), post: (u, b) => call("POST", u, b), patch: (u, b) => call("PATCH", u, b), del: (u) => call("DELETE", u),
  async all(u) { let out = [], next = u; while (next) { const r = await call("GET", next); out = out.concat(r.data); next = r.links?.next; } return out; },
  async upload(op, file) { // perform one upload operation from an asset reservation
    const buf = fs.readFileSync(file).subarray(op.offset, op.offset + op.length);
    const headers = Object.fromEntries((op.requestHeaders || []).map((h) => [h.name, h.value]));
    const r = await fetch(op.url, { method: op.method, headers, body: buf });
    if (!r.ok) throw new Error(`upload ${r.status}`);
  },
  md5: (file) => crypto.createHash("md5").update(fs.readFileSync(file)).digest("hex"),
};

const job = process.argv[2];
const out = path.join(path.dirname(job), path.basename(job, ".mjs") + ".out.json");
try {
  const result = await (await import(path.resolve(job))).default(api);
  fs.writeFileSync(out, JSON.stringify({ ok: true, result }, null, 2));
  console.log("ASC JOB OK");
} catch (e) {
  fs.writeFileSync(out, JSON.stringify({ ok: false, error: String(e.message || e) }, null, 2));
  console.log("ASC JOB FAILED", e.message);
  process.exitCode = 1;
}

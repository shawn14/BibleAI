// Narrow version of fastlane-configs/scripts/create_dev_profile.rb:
// reuse an existing certificate + this connected registered phone; never delete profiles.
import { execFileSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import inspect from './apple-account-preflight.mjs';

export default async (api) => {
  if (!process.env.MAC_RUNNER_JOB_ID || process.env.APPLY_APPLE_ACCOUNT_PROFILE !== '1') {
    throw new Error('Use the approved prepare_account_device action');
  }
  const capability = await inspect(api);
  if (!capability.signInWithAppleEnabled) throw new Error('Apple sign-in capability is not enabled');
  const settings = JSON.parse(execFileSync('ruby', ['-rxcodeproj', '-rjson', '-e',
    'p=Xcodeproj::Project.open("BibleAI.xcodeproj"); ' +
    'a=p.targets.select { |t| t.product_type == "com.apple.product-type.application" }; ' +
    'abort "Expected one app target" unless a.length == 1; ' +
    'puts JSON.generate(a.first.build_configurations.find { |c| c.name == "Debug" }.build_settings)'
  ], { encoding: 'utf8' }));
  const bundle = settings.PRODUCT_BUNDLE_IDENTIFIER, team = settings.DEVELOPMENT_TEAM;
  if (bundle !== capability.identifier || !team) throw new Error('Native target mismatch');
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'bible-account-signing-'));
  try {
    const query = (name, args) => {
      const output = path.join(scratch, name + '.json');
      execFileSync('xcrun', ['devicectl', '--timeout', '30', ...args, '--json-output', output], { timeout: 45000, stdio: ['ignore', 'ignore', 'pipe'] });
      return JSON.parse(fs.readFileSync(output, 'utf8')).result;
    };
    const phones = query('devices', ['list', 'devices']).devices.filter(d =>
      d.hardwareProperties?.deviceType === 'iPhone' && d.connectionProperties?.pairingState === 'paired' &&
      d.connectionProperties?.tunnelState !== 'unavailable' && d.connectionProperties?.transportType);
    if (phones.length !== 1) throw new Error('Require exactly one reachable paired iPhone');
    const phone = phones[0], udid = phone.hardwareProperties.udid;
    if (!udid) throw new Error('Connected phone has no hardware UDID');
    const installed = query('app', ['device', 'info', 'apps', '--device', phone.identifier, '--bundle-id', bundle]).apps;
    if (installed.length !== 1 || installed[0].bundleIdentifier !== bundle) throw new Error('Expected existing Bible app on the connected phone');
    const identities = execFileSync('security', ['find-identity', '-v', '-p', 'codesigning'], { encoding: 'utf8' });
    const local = new Set(identities.match(/\b[0-9A-F]{40}\b/g) || []);
    const certificates = (await api.all('/v1/certificates?limit=200')).filter(c =>
      ['DEVELOPMENT', 'IOS_DEVELOPMENT'].includes(c.attributes.certificateType) &&
      Date.parse(c.attributes.expirationDate) > Date.now()).map(c => ({ ...c,
        hash: crypto.createHash('sha1').update(Buffer.from(c.attributes.certificateContent, 'base64')).digest('hex').toUpperCase()
      })).filter(c => local.has(c.hash)).sort((a,b) => Date.parse(b.attributes.expirationDate) - Date.parse(a.attributes.expirationDate));
    if (!certificates.length) throw new Error('No existing valid local development certificate; no certificate will be created');
    const certificate = certificates[0];
    const devices = (await api.all('/v1/devices?limit=200')).filter(d => d.attributes.udid === udid && d.attributes.status === 'ENABLED' && d.attributes.platform === 'IOS');
    if (devices.length !== 1) throw new Error('Connected phone must already be registered and enabled; no registration will be changed');
    const decode = (content) => {
      const file = path.join(scratch, 'profile.mobileprovision');
      fs.writeFileSync(file, Buffer.from(content, 'base64'), { mode: 0o600 });
      const xml = execFileSync('security', ['cms', '-D', '-i', file], { stdio: ['ignore', 'pipe', 'ignore'] });
      return JSON.parse(execFileSync('python3', ['-c', `import sys,plistlib,json,hashlib
p=plistlib.loads(sys.stdin.buffer.read()); e=p['Entitlements']
print(json.dumps({'team':p['TeamIdentifier'],'appid':e.get('application-identifier'),'devices':p.get('ProvisionedDevices',[]),'expires':p['ExpirationDate'].isoformat()+'Z','development':e.get('get-task-allow'),'apple':e.get('com.apple.developer.applesignin'),'icloud':e.get('com.apple.developer.ubiquity-kvstore-identifier'),'certs':[hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates']],'uuid':p['UUID']}))`], { input: xml, encoding: 'utf8' }));
    };
    const matches = p => p.team.includes(team) && p.appid === team + '.' + bundle && p.devices.includes(udid) &&
      Date.parse(p.expires) > Date.now() && p.development === true && p.apple?.includes('Default') &&
      [team + '.*', team + '.' + bundle].includes(p.icloud) && p.certs.includes(certificate.hash);
    let selected, decoded, writes = 0;
    const profiles = await api.all('/v1/profiles?filter[profileType]=IOS_APP_DEVELOPMENT&include=bundleId&limit=200');
    for (const profile of profiles) {
      if (profile.relationships?.bundleId?.data?.id !== capability.bundleResourceID || profile.attributes.profileState !== 'ACTIVE') continue;
      const candidate = decode(profile.attributes.profileContent);
      if (matches(candidate)) { selected = profile; decoded = candidate; break; }
    }
    if (!selected) {
      selected = (await api.post('/v1/profiles', { data: {
        type: 'profiles', attributes: { name: `${bundle} Account ${Date.now()}`, profileType: 'IOS_APP_DEVELOPMENT' },
        relationships: {
          bundleId: { data: { type: 'bundleIds', id: capability.bundleResourceID } },
          certificates: { data: [{ type: 'certificates', id: certificate.id }] },
          devices: { data: [{ type: 'devices', id: devices[0].id }] }
        }
      }})).data;
      writes = 1;
      decoded = decode(selected.attributes.profileContent);
    }
    if (!matches(decoded)) throw new Error('Created profile does not authorize the requested app, phone, signing identity and capabilities; stop');
    const directory = path.resolve('build/account');
    fs.mkdirSync(directory, { recursive: true });
    const profilePath = path.join(directory, 'development.mobileprovision');
    fs.writeFileSync(profilePath, Buffer.from(selected.attributes.profileContent, 'base64'), { mode: 0o600 });
    return { bundle, team, device: phone.identifier, udid, identity: certificate.hash, profilePath,
      profileUUID: decoded.uuid, appleSignIn: decoded.apple, iCloudKV: decoded.icloud, writes,
      source: execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(),
      scope: 'Development profile only; no new certificate, device registration, deletion or store upload' };
  } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
};

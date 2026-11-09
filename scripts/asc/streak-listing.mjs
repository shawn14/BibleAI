// Update the English product page of the 2.0.3 draft. Existing previews, other
// localizations and the public 2.0.2 listing belong to different resources.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { screenshotSet } from './store-assets.mjs';

const app = '6756225286';
const version = '2.0.3';
const group = [
  ['APP_IPHONE_67', 'screenshots-6.9'],
  ['APP_IPHONE_61', 'screenshots-6.3'],
  ['APP_IPAD_PRO_3GEN_129', 'screenshots-ipad-13'],
];
const root = path.resolve('docs/aso');
const copy = key => fs.readFileSync(path.join(root, 'en-US', key + '.txt'), 'utf8').trim();
const editable = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'METADATA_REJECTED', 'REJECTED']);
const distributed = new Set(['READY_FOR_SALE', 'READY_FOR_DISTRIBUTION']);
const state = record => record.attributes.appStoreState || record.attributes.state;
function only(records, label) {
  assert.equal(records.length, 1, 'Expected one ' + label);
  return records[0];
}
async function writeFields(api, type, record, attributes) {
  if (Object.entries(attributes).some(([key, value]) => record.attributes[key] !== value)) {
    await api.patch('/v1/' + type + '/' + record.id, { data: { type, id: record.id, attributes } });
  }
}

export default async function listing(api) {
  const apply = process.env.STREAK_LISTING_MODE === 'apply';
  const appRecord = (await api.get('/v1/apps/' + app)).data;
  assert.equal(appRecord.attributes.bundleId, 'com.shawncarpenter.bibleai-companion');
  const versions = await api.all('/v1/apps/' + app + '/appStoreVersions?filter[platform]=IOS');
  // Apple retains the distributed state on earlier versions after an update ships.
  const live = versions.filter(v => distributed.has(state(v)))
    .sort((a, b) => b.attributes.versionString.localeCompare(a.attributes.versionString, 'en', {numeric: true}))[0];
  assert(live, 'Missing distributed version');
  assert.equal(live.attributes.versionString, '2.0.2');
  assert(!versions.some(v => editable.has(state(v)) && v.attributes.versionString !== version), 'Another editable version exists');
  let draft = versions.find(v => v.attributes.versionString === version);
  const sets = group.map(([display, dir]) => {
    const files = fs.readdirSync(path.join(root, dir)).filter(f => f.endsWith('.png')).sort().map(f => path.join(root, dir, f));
    assert.equal(files.length, 6);
    return { display, files, hashes: files.map(f => api.md5(f)) };
  });
  if (!draft && apply) {
    draft = (await api.post('/v1/appStoreVersions', { data: {
      type: 'appStoreVersions', attributes: { platform: 'IOS', versionString: version, releaseType: 'MANUAL', copyright: live.attributes.copyright },
      relationships: { app: { data: { type: 'apps', id: app } } },
    } })).data;
  }
  assert(draft, 'Missing target version');
  if (apply) assert(editable.has(state(draft)), 'Target version is not editable');
  assert.equal(draft.attributes.releaseType, 'MANUAL');
  const locales = await api.all('/v1/appStoreVersions/' + draft.id + '/appStoreVersionLocalizations');
  const locale = only(locales.filter(l => l.attributes.locale === 'en-US'), 'en-US version locale');
  const infos = await api.all('/v1/apps/' + app + '/appInfos');
  const info = only(infos.filter(i => !distributed.has(state(i)) && state(i) === state(draft)), 'matching pending app information');
  const infoLocale = only((await api.all('/v1/appInfos/' + info.id + '/appInfoLocalizations')).filter(l => l.attributes.locale === 'en-US'), 'en-US information');
  assert.equal(infoLocale.attributes.name, copy('name'));
  const infoFields = { subtitle: copy('subtitle') };
  const fields = { description: copy('description'), keywords: copy('keywords'), promotionalText: copy('promotional_text'), whatsNew: copy('release_notes') };
  if (apply) {
    await writeFields(api, 'appInfoLocalizations', infoLocale, infoFields);
    await writeFields(api, 'appStoreVersionLocalizations', locale, fields);
    fs.mkdirSync('build/aso-refresh', {recursive: true});
  }
  for (const [type, id, expected] of [['appInfoLocalizations', infoLocale.id, infoFields], ['appStoreVersionLocalizations', locale.id, fields]]) {
    const current = (await api.get('/v1/' + type + '/' + id)).data.attributes;
    for (const [key, value] of Object.entries(expected)) assert.equal(current[key], value, key);
  }
  async function shots(display) {
    const collections = await api.all('/v1/appStoreVersionLocalizations/' + locale.id + '/appScreenshotSets');
    const collection = collections.find(s => s.attributes.screenshotDisplayType === display);
    return collection ? api.all('/v1/appScreenshotSets/' + collection.id + '/appScreenshots') : [];
  }
  const checksum = shot => shot.attributes.sourceFileChecksum;
  const uploaded = shot => shot.attributes.assetDeliveryState?.state;
  // Apple's sourceFileChecksum may be null during processing. Preserve a
  // matching in-flight set and upload the other device sizes independently.
  if (apply) {
    for (const {display, files, hashes} of sets) {
      const assets = await shots(display);
      const same = assets.length === files.length && assets.every((a, i) => {
        const pending = !checksum(a) && ['UPLOAD_COMPLETE', 'PROCESSING'].includes(uploaded(a));
        return a.attributes.fileName === path.basename(files[i])
          && a.attributes.fileSize === fs.statSync(files[i]).size
          && (checksum(a) === hashes[i] || pending);
      });
      if (!same) await screenshotSet(api, locale.id, display, files);
    }
  }
  const pending = [];
  for (const {display, files, hashes} of sets) {
    const assets = await shots(display);
    assert.deepEqual(assets.map(a => a.attributes.fileName), files.map(f => path.basename(f)), display);
    for (const [index, shot] of assets.entries()) {
      assert.equal(shot.attributes.fileSize, fs.statSync(files[index]).size);
      const delivery = uploaded(shot);
      if (delivery === 'COMPLETE') assert.equal(checksum(shot), hashes[index], shot.attributes.fileName);
      else {
        assert(['UPLOAD_COMPLETE', 'PROCESSING'].includes(delivery), shot.attributes.fileName + ': ' + delivery);
        pending.push(shot.attributes.fileName);
      }
    }
  }
  if (!apply) assert.equal(pending.length, 0, 'Apple is processing: ' + pending.join(', '));
  let build;
  try {
    build = (await api.get('/v1/appStoreVersions/' + draft.id + '/build')).data;
  } catch (error) {
    if (error.status !== 404) throw error;
  }
  return { version, state: state(draft), release: draft.attributes.releaseType, build: build?.attributes?.version, processing: build?.attributes?.processingState, subtitle: infoFields.subtitle, screenshots: 18, pending };
}

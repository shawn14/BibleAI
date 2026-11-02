#!/usr/bin/env python3
"""Join explicit GrowthStore exports. Never labels a selected device sample as population K.
Input: {observedAt: ISO8601, snapshot: <GrowthStore.exportSnapshotData JSON>}.
observedAt is the collection time, not a guessed time from an event or filesystem mtime.
"""
import argparse
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
from uuid import UUID

KINDS = {'sharePresented', 'shareCompleted', 'shareCancelled', 'shareFailed',
         'invitationOpened', 'invitationAccepted', 'firstReading'}
WINDOW = timedelta(days=30)


def instant(value):
    if not isinstance(value, str):
        raise ValueError('Timestamps must be ISO8601 strings with a timezone')
    try:
        result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError as exc:
        raise ValueError('Invalid timestamp') from exc
    if result.tzinfo is None:
        raise ValueError('Naive timestamps cannot define a referral window')
    return result.astimezone(timezone.utc)


def identity(value):
    if not isinstance(value, str) or len(value) != 36:
        raise ValueError('Expected a canonical UUID')
    parsed = str(UUID(value))
    if parsed != value.lower():
        raise ValueError('Expected a canonical UUID')
    return parsed


def target(invitation):
    """Compare exact public targets; never emit their text or IDs in the aggregate report."""
    if not isinstance(invitation, dict):
        raise ValueError('Missing invitation')
    token = identity(invitation.get('inviteID'))
    kind = invitation.get('kind')
    if kind == 'verse':
        book = invitation.get('book')
        chapter, verse = invitation.get('chapter'), invitation.get('verse')
        if not isinstance(book, str) or not 1 <= len(book) <= 32:
            raise ValueError('Invalid verse target')
        if type(chapter) is not int or type(verse) is not int or not 1 <= chapter <= 150 or not 1 <= verse <= 176:
            raise ValueError('Invalid verse target')
        if invitation.get('planID') is not None:
            raise ValueError('Mixed invitation target')
        return token, (kind, book, chapter, verse)
    if kind == 'plan':
        if any(invitation.get(key) is not None for key in ('book', 'chapter', 'verse')):
            raise ValueError('Mixed invitation target')
        return token, (kind, identity(invitation.get('planID')))
    raise ValueError('Unknown invitation kind')


def normalize(envelope, as_of):
    observed = instant(envelope.get('observedAt'))
    if observed > as_of:
        raise ValueError('Collection time is after report as-of time')
    snapshot = envelope.get('snapshot', {})
    if snapshot.get('schemaVersion') != 1:
        raise ValueError('Unsupported GrowthStore export schema')
    install = identity(snapshot.get('installationID'))
    first_seen = instant(snapshot.get('firstSeenAt'))
    activated = instant(snapshot['readerActivatedAt']) if snapshot.get('readerActivatedAt') else None
    if first_seen > observed or (activated and not first_seen <= activated <= observed):
        raise ValueError('Invalid installation activation chronology')
    events = snapshot.get('events')
    if not isinstance(events, list) or len(events) > 200:
        raise ValueError('Expected at most 200 retained native events')
    counters = snapshot.get('counters', {})
    if not isinstance(counters, dict) or any(k not in KINDS | {'readerActivated'} or type(v) is not int or v < 0 for k, v in counters.items()):
        raise ValueError('Invalid native counters')
    if counters.get('readerActivated', 0) != int(activated is not None):
        raise ValueError('Activation counter disagrees with activation timestamp')
    unique = {}
    for event in events:
        event_id, kind = identity(event.get('id')), event.get('kind')
        if kind not in KINDS:
            raise ValueError('Unknown event kind')
        when = instant(event.get('recordedAt'))
        if not first_seen <= when <= observed:
            raise ValueError('Event outside observed installation lifetime')
        token, content = target(event.get('invitation'))
        value = (kind, when, token, content)
        if event_id in unique and unique[event_id] != value:
            raise ValueError('Conflicting event replay')
        unique[event_id] = value
    retained = Counter(e[0] for e in unique.values())
    if any(counters.get(kind, 0) < count for kind, count in retained.items()):
        raise ValueError('Counters smaller than retained event history')
    attribution = snapshot.get('attribution')
    if attribution:
        token, content = target(attribution.get('invitation'))
        opened = instant(attribution.get('openedAt'))
        accepted = instant(attribution['acceptedAt']) if attribution.get('acceptedAt') else None
        read = instant(attribution['activatedAt']) if attribution.get('activatedAt') else None
        if type(attribution.get('isNewReader')) is not bool or not first_seen <= opened <= observed:
            raise ValueError('Invalid attribution')
        if accepted and not opened <= accepted <= observed:
            raise ValueError('Acceptance before opening')
        if read and (not accepted or not accepted <= read <= observed):
            raise ValueError('Reading before acceptance')
        if read and not activated:
            raise ValueError('Attributed reading has no eligible-reader baseline')
        attribution = (token, content, opened, accepted, read, attribution['isNewReader'])
    return {'id': install, 'first': first_seen, 'active': activated, 'observed': observed,
            'events': unique, 'counters': counters, 'attribution': attribution}


def summarize(envelopes, cohort_start, cohort_end, as_of):
    start, end, now = map(instant, (cohort_start, cohort_end, as_of))
    if not start < end <= now:
        raise ValueError('Require cohort start < end <= as-of')
    installations = {}
    seen_event_ids = {}
    records = sorted((normalize(e, now) for e in envelopes), key=lambda r: r['observed'])
    for record in records:
        for event_id in record['events']:
            if event_id in seen_event_ids and seen_event_ids[event_id] != record['id']:
                raise ValueError('One native event appears under multiple installations')
            seen_event_ids[event_id] = record['id']
        prior = installations.get(record['id'])
        if prior:
            if record['first'] != prior['first'] or (prior['active'] and record['active'] != prior['active']):
                raise ValueError('Installation history changed identity or activation')
            if any(record['counters'].get(k, 0) < v for k, v in prior['counters'].items()):
                raise ValueError('Lifetime counters went backward')
            old, new = prior['attribution'], record['attribution']
            if old and (not new or old[:3] != new[:3] or old[5] != new[5]
                        or any(old[i] and old[i] != new[i] for i in (3, 4))):
                raise ValueError('First attribution was overwritten')
            merged = dict(prior['events'])
            for event_id, value in record['events'].items():
                if event_id in merged and merged[event_id] != value:
                    raise ValueError('Conflicting event replay')
                merged[event_id] = value
            record['events'] = merged
        installations[record['id']] = record
    seeds = {key: r for key, r in installations.items() if r['active'] and start <= r['active'] < end}
    mature = {key for key, r in seeds.items() if r['observed'] >= r['active'] + WINDOW}
    owners = defaultdict(dict)
    for key, record in installations.items():
        for kind, when, token, content in record['events'].values():
            if kind != 'shareCompleted':
                continue
            owner = (key, content)
            owners[token][owner] = min(owners[token].get(owner, when), when)
    referrals, exclusions = {}, Counter()
    for key, record in installations.items():
        a = record['attribution']
        if not a or not a[4]:
            continue
        token, content, opened, accepted, read, is_new = a
        if not is_new:
            exclusions['returningReader'] += 1
            continue
        candidates = owners.get(token, {})
        if len(candidates) != 1:
            exclusions['ambiguousInvitation' if candidates else 'senderNotObserved'] += 1
            continue
        (sender, sent_content), sent = next(iter(candidates.items()))
        if sender == key:
            exclusions['selfReferral'] += 1
        elif sent_content != content:
            exclusions['targetMismatch'] += 1
        elif sender not in seeds:
            exclusions['senderOutsideCohort'] += 1
        elif not seeds[sender]['active'] <= sent <= opened <= accepted <= read <= seeds[sender]['active'] + WINDOW:
            exclusions['outsideWindowOrChronology'] += 1
        else:
            referrals[key] = sender
    missing_history = sum(any(count > sum(e[0] == kind for e in r['events'].values())
                              for kind, count in r['counters'].items() if kind in KINDS)
                          for r in installations.values())
    matured_referrals = sum(sender in mature for sender in referrals.values())
    return {
        'schemaVersion': 1, 'cohortStart': cohort_start, 'cohortEnd': cohort_end, 'asOf': as_of,
        'measurementScope': 'Explicitly collected installation sample; population coverage unknown',
        'populationK30': None,
        'observedInstallations': len(installations), 'eligibleSeedInstallations': len(seeds),
        'matureSeedInstallations': len(mature), 'immatureSeedInstallations': len(seeds) - len(mature),
        'observedActivatedReferrals': len(referrals), 'observedActivatedReferralsFromMatureSeeds': matured_referrals,
        'observedReferralsPerEligibleSeed': len(referrals) / len(seeds) if seeds else None,
        'observedReferralsPerMatureSeed': matured_referrals / len(mature) if mature else None,
        'installationsWithMissingRawHistory': missing_history,
        'excludedAttributedActivations': dict(sorted(exclusions.items())),
        'limits': ['Missing seed/recipient exports and bounded native history can change these sample ratios.',
                   'An installation is not a person; reinstalling resets identity.',
                   'Client-reported events are not verified delivery or App Store install receipts.',
                   'No live K-factor or viral-growth claim follows from test fixtures or this selected sample.'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cohort-start', required=True)
    parser.add_argument('--cohort-end', required=True)
    parser.add_argument('--as-of', required=True)
    parser.add_argument('exports', nargs='*', type=Path)
    args = parser.parse_args()
    try:
        if any(p.stat().st_size > 2_000_000 for p in args.exports):
            raise ValueError('One export exceeds the 2 MB bound')
        records = [json.loads(p.read_text()) for p in args.exports]
        result = summarize(records, args.cohort_start, args.cohort_end, args.as_of)
    except (ValueError, OSError, TypeError, KeyError) as exc:
        parser.exit(1, f'Referral report refused: {exc}\n')
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    main()

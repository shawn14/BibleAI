"""Synthetic arithmetic fixtures. These are NOT observed Bright Scroll user-growth results."""
from copy import deepcopy
from datetime import datetime, timedelta, timezone
import unittest
from uuid import uuid4
from referral_report import summarize

T = datetime(2026, 1, 1, tzinfo=timezone.utc)
def iso(days): return (T + timedelta(days=days)).isoformat().replace('+00:00', 'Z')
def uid(): return str(uuid4())
def invitation(token=None, book='John'):
    return {'kind': 'verse', 'book': book, 'chapter': 3, 'verse': 16, 'inviteID': token or uid()}
def event(kind, link, day):
    return {'id': uid(), 'kind': kind, 'invitation': link, 'recordedAt': iso(day)}
def device(active=0, observed=40):
    return {'observedAt': iso(observed), 'snapshot': {
        'schemaVersion': 1, 'installationID': uid(), 'firstSeenAt': iso(0),
        'readerActivatedAt': iso(active) if active is not None else None,
        'events': [], 'counters': {'readerActivated': int(active is not None)}}}
def add(record, item):
    s = record['snapshot']; s['events'].append(item)
    s['counters'][item['kind']] = s['counters'].get(item['kind'], 0) + 1
    return record

def referred(link, read=3, is_new=True):
    result = device(active=read)
    result['snapshot']['attribution'] = {'invitation': link, 'openedAt': iso(2),
        'acceptedAt': iso(2), 'activatedAt': iso(read), 'isNewReader': is_new}
    add(result, event('firstReading', link, read))
    return result

def report(*records): return summarize(records, iso(0), iso(1), iso(50))

class ReferralReportTests(unittest.TestCase):
    def setUp(self):
        self.link = invitation()
        self.seed = add(device(), event('shareCompleted', self.link, 1))
        self.recipient = referred(self.link)

    def test_empty_data_withholds_rates(self):
        out = report()
        self.assertIsNone(out['populationK30'])
        self.assertIsNone(out['observedReferralsPerEligibleSeed'])
        self.assertEqual(out['eligibleSeedInstallations'], 0)

    def test_two_referrals_over_two_seeds_includes_nonsharing_reader(self):
        out = report(self.seed, device(), self.recipient, referred(self.link, read=5))
        self.assertEqual(out['eligibleSeedInstallations'], 2)
        self.assertEqual(out['observedActivatedReferrals'], 2)
        self.assertEqual(out['observedReferralsPerMatureSeed'], 1)
        self.assertIsNone(out['populationK30'])

    def test_repeated_export_and_repeated_activity_do_not_duplicate_recipient(self):
        add(self.seed, event('shareCompleted', self.link, 1.5))
        out = report(self.seed, deepcopy(self.seed), self.recipient, deepcopy(self.recipient))
        self.assertEqual(out['observedInstallations'], 2)
        self.assertEqual(out['observedActivatedReferrals'], 1)

    def test_presented_or_cancelled_share_is_not_a_sent_invitation(self):
        for kind in ('sharePresented', 'shareCancelled', 'shareFailed'):
            seed = add(device(), event(kind, self.link, 1))
            out = report(seed, self.recipient)
            self.assertEqual(out['observedActivatedReferrals'], 0)
            self.assertEqual(out['excludedAttributedActivations'], {'senderNotObserved': 1})

    def test_returning_reader_is_excluded(self):
        out = report(self.seed, referred(self.link, is_new=False))
        self.assertEqual(out['excludedAttributedActivations'], {'returningReader': 1})
        self.assertEqual(out['observedActivatedReferrals'], 0)

    def test_self_referral_is_excluded(self):
        self.recipient['snapshot']['installationID'] = self.seed['snapshot']['installationID']
        self.recipient['snapshot']['readerActivatedAt'] = self.seed['snapshot']['readerActivatedAt']
        self.recipient['snapshot']['events'] = self.seed['snapshot']['events']
        self.recipient['snapshot']['counters'] = self.seed['snapshot']['counters']
        out = report(self.recipient)
        self.assertEqual(out['excludedAttributedActivations'], {'selfReferral': 1})

    def test_token_collision_or_content_change_cannot_invent_a_sender(self):
        other = add(device(), event('shareCompleted', self.link, 1))
        out = report(self.seed, other, self.recipient)
        self.assertEqual(out['excludedAttributedActivations'], {'ambiguousInvitation': 1})
        different = referred(invitation(self.link['inviteID'], book='Luke'))
        out = report(self.seed, different)
        self.assertEqual(out['excludedAttributedActivations'], {'targetMismatch': 1})

    def test_mature_window_includes_boundary_but_not_later_reading(self):
        self.assertEqual(report(self.seed, referred(self.link, read=30))['observedActivatedReferrals'], 1)
        out = report(self.seed, referred(self.link, read=30.001))
        self.assertEqual(out['excludedAttributedActivations'], {'outsideWindowOrChronology': 1})
        early = referred(self.link)
        early['snapshot']['attribution']['openedAt'] = iso(.5)
        self.assertEqual(report(self.seed, early)['observedActivatedReferrals'], 0)

    def test_immature_seed_is_not_reported_as_30_day_result(self):
        self.seed['observedAt'] = iso(10)
        out = report(self.seed, self.recipient)
        self.assertEqual(out['immatureSeedInstallations'], 1)
        self.assertEqual(out['observedActivatedReferrals'], 1)
        self.assertIsNone(out['observedReferralsPerMatureSeed'])

    def test_missing_history_warns_and_earlier_exports_recover_join(self):
        old = deepcopy(self.seed); old['observedAt'] = iso(5)
        self.seed['snapshot']['events'] = []
        out = report(self.seed, self.recipient)
        self.assertEqual(out['installationsWithMissingRawHistory'], 1)
        self.assertEqual(out['observedActivatedReferrals'], 0)
        recovered = report(self.seed, old, self.recipient)
        self.assertEqual(recovered['observedActivatedReferrals'], 1)
        self.assertEqual(recovered['installationsWithMissingRawHistory'], 0)

    def test_regressing_counters_and_changed_attribution_are_rejected(self):
        old = deepcopy(self.seed); old['observedAt'] = iso(5)
        self.seed['snapshot']['events'] = []
        self.seed['snapshot']['counters']['shareCompleted'] = 0
        with self.assertRaisesRegex(ValueError, 'backward'): report(old, self.seed)
        old = deepcopy(self.recipient); old['observedAt'] = iso(5)
        self.recipient['snapshot']['attribution']['invitation'] = invitation()
        with self.assertRaisesRegex(ValueError, 'overwritten'): report(old, self.recipient)

    def test_conflicting_event_identity_is_rejected(self):
        old = deepcopy(self.seed); old['observedAt'] = iso(5)
        self.seed['snapshot']['events'][0]['invitation'] = invitation()
        with self.assertRaisesRegex(ValueError, 'Conflicting'): report(old, self.seed)
        other = deepcopy(old); other['snapshot']['installationID'] = uid()
        with self.assertRaisesRegex(ValueError, 'multiple installations'): report(old, other)

    def test_impossible_chronology_and_unknown_schema_are_rejected(self):
        self.recipient['snapshot']['attribution']['acceptedAt'] = iso(4)
        with self.assertRaisesRegex(ValueError, 'before acceptance'): report(self.seed, self.recipient)
        self.seed['snapshot']['schemaVersion'] = 99
        with self.assertRaisesRegex(ValueError, 'schema'): report(self.seed)
        with self.assertRaises(ValueError): summarize([], '2026-01-01', iso(1), iso(50))

    def test_aggregate_output_contains_no_link_tokens_or_content(self):
        import json
        output = json.dumps(report(self.seed, self.recipient))
        for value in (self.link['inviteID'], self.seed['snapshot']['installationID'], 'John'):
            self.assertNotIn(value, output)

if __name__ == '__main__': unittest.main()

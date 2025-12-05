import asyncio
import unittest
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

from src.services.scrum_master_service import ScrumMasterService

# Mock data
MOCK_ISSUES = [
    {
        "number": 1,
        "title": "Feature A",
        "state": "closed",
        "created_at": (datetime.now(UTC) - timedelta(days=10))
        .isoformat()
        .replace("+00:00", "Z"),
        "closed_at": (datetime.now(UTC) - timedelta(days=2))
        .isoformat()
        .replace("+00:00", "Z"),
        "labels": ["sprint:atual"],
        "assignee": {"login": "dev1"},
    },
    {
        "number": 2,
        "title": "Bug Fix B",
        "state": "closed",
        "created_at": (datetime.now(UTC) - timedelta(days=5))
        .isoformat()
        .replace("+00:00", "Z"),
        "closed_at": (datetime.now(UTC) - timedelta(days=1))
        .isoformat()
        .replace("+00:00", "Z"),
        "labels": ["sprint:atual", "bug"],
        "assignee": {"login": "dev2"},
    },
    {
        "number": 3,
        "title": "Feature C",
        "state": "open",
        "created_at": (datetime.now(UTC) - timedelta(days=3))
        .isoformat()
        .replace("+00:00", "Z"),
        "labels": ["sprint:atual", "bloqueado"],
        "assignee": {"login": "dev1"},
    },
    {
        "number": 4,
        "title": "Unplanned Task",
        "state": "open",
        "created_at": (datetime.now(UTC) - timedelta(hours=2))
        .isoformat()
        .replace("+00:00", "Z"),  # Very recent
        "labels": ["sprint:atual"],
        "assignee": {"login": "dev3"},
    },
]

MOCK_EVENTS = [
    # Events for Issue 1
    {
        "event": "labeled",
        "label": "sprint:atual",
        "created_at": (datetime.now(UTC) - timedelta(days=9))
        .isoformat()
        .replace("+00:00", "Z"),
    },
    # Events for Issue 2
    {
        "event": "labeled",
        "label": "sprint:atual",
        "created_at": (datetime.now(UTC) - timedelta(days=4))
        .isoformat()
        .replace("+00:00", "Z"),
    },
    {
        "event": "labeled",
        "label": "status:aguardando-correcao-doc",
        "created_at": (datetime.now(UTC) - timedelta(days=3))
        .isoformat()
        .replace("+00:00", "Z"),
    },  # Rework
]


class TestScrumMetrics(unittest.TestCase):
    def test_calculate_advanced_metrics(self):
        asyncio.run(self._test_calculate_advanced_metrics_async())

    async def _test_calculate_advanced_metrics_async(self):
        service = ScrumMasterService()

        # Use AsyncMock for async functions
        with patch(
            "src.services.scrum_master_service.list_issues_by_label",
            new_callable=MagicMock,
        ) as mock_list_issues:
            with patch(
                "src.services.scrum_master_service.get_issue_events",
                new_callable=MagicMock,
            ) as mock_get_events:
                # Configure mocks to be awaitable
                f_issues = asyncio.Future()
                f_issues.set_result(MOCK_ISSUES)
                mock_list_issues.return_value = f_issues

                # Mock events based on issue number
                def get_events_side_effect(issue_number):
                    f = asyncio.Future()
                    if issue_number == 1:
                        f.set_result([MOCK_EVENTS[0]])
                    elif issue_number == 2:
                        f.set_result([MOCK_EVENTS[1], MOCK_EVENTS[2]])
                    else:
                        f.set_result([])
                    return f

                mock_get_events.side_effect = get_events_side_effect

                metrics = await service.calculate_advanced_metrics()

                print("\n--- Metrics Calculated ---")
                print(metrics)

                # Assertions

                # Flow
                # Lead Time 1: 8 days (10-2)
                # Lead Time 2: 4 days (5-1)
                # Avg Lead Time: (8+4)/2 = 6.0
                self.assertEqual(metrics["flow"]["lead_time_avg_days"], 6.0)

                # Cycle Time 1: 7 days (9-2) (Started 9 days ago, closed 2 days ago)
                # Cycle Time 2: 3 days (4-1) (Started 4 days ago, closed 1 day ago)
                # Avg Cycle Time: (7+3)/2 = 5.0
                self.assertEqual(metrics["flow"]["cycle_time_avg_days"], 5.0)

                # WIP: 2 open issues (3 and 4)
                self.assertEqual(metrics["flow"]["wip"], 2)

                # Quality
                # Bugs: 1 (Issue 2)
                self.assertEqual(metrics["quality"]["bugs_count"], 1)
                # Rework: 1 (Issue 2 has rework event)
                self.assertEqual(metrics["quality"]["rework_count"], 1)

                # Health
                # Blockers: 1 (Issue 3)
                self.assertEqual(metrics["health"]["blockers_count"], 1)

                # Predictability
                # Unplanned: 1 (Issue 4 created very recently)
                self.assertGreaterEqual(metrics["predictability"]["unplanned_items"], 1)


if __name__ == "__main__":
    unittest.main()

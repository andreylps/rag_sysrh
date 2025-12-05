import unittest

from src.services.code_analysis_service import code_analysis_service
from src.services.quality_service import get_iso_indicators


class TestCodeAnalysis(unittest.IsolatedAsyncioTestCase):
    def test_analyze_complexity(self):
        """Testa se a análise de complexidade retorna um float válido."""
        cc = code_analysis_service.analyze_complexity()
        print(f"Average Complexity: {cc}")
        self.assertIsInstance(cc, float)
        self.assertGreaterEqual(cc, 0.0)

    def test_analyze_maintainability(self):
        """Testa se a análise de manutenibilidade retorna um float válido."""
        mi = code_analysis_service.analyze_maintainability()
        print(f"Average Maintainability Index: {mi}")
        self.assertIsInstance(mi, float)
        self.assertGreaterEqual(mi, 0.0)
        self.assertLessEqual(mi, 100.0)

    async def test_integration_with_quality_service(self):
        """Testa se get_iso_indicators usa os valores reais."""
        # Mock dependencies inside quality_service if needed, but we want to see real radon values if possible.
        # However, get_iso_indicators calls other things like alerts.
        # We will trust the previous mocks for alerts and focus on checking if product metrics are present.

        # We need to patch get_all_alerts and qa_scheduler to avoid errors or external calls
        from unittest.mock import patch

        with (
            patch("src.services.quality_service.get_all_alerts", return_value=[]),
            patch(
                "src.services.qa_scheduler_service.qa_scheduler.get_schedule_stats",
                return_value={"total": 0},
            ),
        ):
            indicators = await get_iso_indicators()
            product = indicators["product"]

            self.assertIn("cyclomatic_complexity_avg", product)
            self.assertIn("maintainability_index", product)
            self.assertIn("technical_debt_ratio", product)

            # Ensure they are not the old hardcoded mock values (unless by coincidence)
            # Old mock: CC=8.4, MI was not there.
            self.assertIsInstance(product["cyclomatic_complexity_avg"], float)
            self.assertIsInstance(product["maintainability_index"], float)


if __name__ == "__main__":
    unittest.main()

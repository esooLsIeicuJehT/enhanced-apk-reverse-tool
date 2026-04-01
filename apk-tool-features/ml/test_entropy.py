
import sys
import unittest
from unittest.mock import MagicMock
import math

# Mocking modules that are missing in the environment
mock_joblib = MagicMock()
sys.modules['joblib'] = mock_joblib
mock_np = MagicMock()
mock_np.log2.side_effect = lambda x: math.log2(x)
sys.modules['numpy'] = mock_np

# Import the class to test
from malware_detector import FeatureExtractor

class TestPermissionEntropy(unittest.TestCase):
    def test_calculate_permission_entropy_empty(self):
        extractor = FeatureExtractor("dummy.apk")
        extractor.permissions = []
        entropy = extractor._calculate_permission_entropy()
        self.assertEqual(entropy, 0.0)

    def test_calculate_permission_entropy_no_dots(self):
        extractor = FeatureExtractor("dummy.apk")
        extractor.permissions = ["INTERNET", "CAMERA"]
        entropy = extractor._calculate_permission_entropy()
        self.assertEqual(entropy, 0.0)

    def test_calculate_permission_entropy_with_prefixes(self):
        extractor = FeatureExtractor("dummy.apk")
        extractor.permissions = [
            "android.permission.CAMERA",
            "android.permission.INTERNET",
            "com.google.android.c2dm.permission.RECEIVE"
        ]
        # Prefixes: ["android.permission", "android.permission", "com.google.android.c2dm.permission"]
        # Counts: "android.permission": 2, "com.google.android.c2dm.permission": 1
        # Total: 3
        # Probabilities: 2/3, 1/3
        expected_entropy = -(2/3 * math.log2(2/3) + 1/3 * math.log2(1/3))
        entropy = extractor._calculate_permission_entropy()
        self.assertAlmostEqual(entropy, expected_entropy)

if __name__ == "__main__":
    unittest.main()

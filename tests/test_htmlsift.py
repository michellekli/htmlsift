import src.python.sanitizer
import src.python.parser
import unittest
import doctest


def load_tests(
    loader: unittest.TestLoader, tests: unittest.TestSuite, pattern: str
) -> unittest.TestSuite:
    tests.addTests(doctest.DocTestSuite(src.python.sanitizer))
    tests.addTests(doctest.DocTestSuite(src.python.parser))
    return tests

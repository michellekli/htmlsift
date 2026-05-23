import src.python.hello
import unittest
import doctest


def load_tests(
    loader: unittest.TestLoader, tests: unittest.TestSuite, pattern: str
) -> unittest.TestSuite:
    tests.addTests(doctest.DocTestSuite(src.python.hello))
    return tests

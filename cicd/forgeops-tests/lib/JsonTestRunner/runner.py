"""
This runner is just a copy of TextTestRunner adjusted to create a JSON reports and enable our test results to be
put into database for further use.
"""
import json
import os
import sys
import time
import warnings

from unittest import result
from unittest.signals import registerResult


__unittest = True

# Test results definitions
FAIL = "FAIL"
SUCCESS = "SUCCESS"
ERROR = "ERROR"
SKIPPED = "SKIPPED"


def get_test_module(test):
    return type(test).__name__


def get_test_name(test):
    return str(test).split(" ")[0]


def get_test_description(test):
    return test.shortDescription()


class _WritelnDecorator(object):
    """Used to decorate file-like objects with a handy 'writeln' method"""
    def __init__(self, stream):
        self.stream = stream

    def __getattr__(self, attr):
        if attr in ('stream', '__getstate__'):
            raise AttributeError(attr)
        return getattr(self.stream,attr)

    def writeln(self, arg=None):
        if arg:
            self.write(arg)
        self.write('\n')


class JsonTestResultStructure(object):
    def __init__(self, test, test_result, error=None, additional_info="none"):
        self.test_name = get_test_name(test)
        self.module_name = get_test_module(test)
        self.description = get_test_description(test)
        self.result = test_result
        self.error = error
        self.additional_info = additional_info


class JsonTestResults(result.TestResult):
    results = []
    test_start_time = ""
    tests_duration = ""

    def __init__(self, stream, descriptions, verbosity):
        super(JsonTestResults, self).__init__(stream, descriptions, verbosity)
        self.stream = stream
        self.showAll = verbosity > 1
        self.descriptions = descriptions

    def addSuccess(self, test):
        res = JsonTestResultStructure(test, SUCCESS)
        self.results.append(res)

    def addFailure(self, test, err):
        res = JsonTestResultStructure(test, FAIL, error=err)
        self.failures.append(test)
        self.results.append(res)

    def addError(self, test, err):
        res = JsonTestResultStructure(test, ERROR, error=err)
        self.errors.append(test)
        self.results.append(res)

    def addSkip(self, test, reason):
        res = JsonTestResultStructure(test, SKIPPED, error=reason)
        self.results.append(res)

    def set_test_time(self, start, duration):
        self.test_start_time = start
        self.tests_duration = duration

    def dump_results_into_json(self, filepath):
        """
        Use test records to create JSON report and dumps results into file specified by filepath
        :param filepath: Path to report file.
        """
        report_name = None
        result_dict = {"testclasses": [],
                       "start_time": self.test_start_time,
                       "duration": self.tests_duration,
                       "tests_count": self.testsRun,
                       "tests_failed": len(self.failures),
                       "tests_error": len(self.errors)}

        for r in self.results:
            if not result_dict["testclasses"].__contains__({"testclass": r.module_name}):
                result_dict["testclasses"].append(
                    {
                        "testclass": r.module_name
                    }
                )
            if report_name is None:
                report_name = time.strftime("%Y-%m-%d_%H:%M:%S-", time.gmtime()) + "report.json"
        for r in self.results:
            for f in result_dict["testclasses"]:
                for x in f:
                    if f[x] == r.module_name:
                        if not f.__contains__("tests"):
                            f.update({"tests": []})

                        if r.error is not None:
                            err_class, error_message, traceback_obj = r.error
                        else:
                            error_message = ""
                        f["tests"].append(
                            {
                                "testname": r.test_name,
                                "description": r.description,
                                "result": r.result,
                                "error": str(error_message),
                                "additional_info": r.additional_info
                            }
                            )
                        break

        report = json.dumps(result_dict, indent=4)

        with open(os.path.join(filepath, report_name), 'w') as f:
            f.write(report)


class JsonTestRunner(object):
    """JSON test runner is a class that export results in JSON format."""

    resultclass = JsonTestResults

    def __init__(self, stream=None, descriptions=True, verbosity=1,
                 failfast=False, buffer=False, resultclass=None, warnings=None,
                 *, tb_locals=False, report_path=None):

        if stream is None:
            stream = sys.stderr
        self.stream = _WritelnDecorator(stream)
        self.descriptions = descriptions
        self.verbosity = verbosity
        self.failfast = failfast
        self.buffer = buffer
        self.tb_locals = tb_locals
        self.warnings = warnings
        self.report_path = report_path
        if resultclass is not None:
            self.resultclass = resultclass

    def _make_result(self):
        return self.resultclass(self.stream, self.descriptions, self.verbosity)

    def run(self, test):
        """Run the given test case or test suite."""
        results = self._make_result()
        registerResult(results)
        results.failfast = self.failfast
        results.buffer = self.buffer
        results.tb_locals = self.tb_locals
        with warnings.catch_warnings():
            if self.warnings:
                # if self.warnings is set, use it to filter all the warnings
                warnings.simplefilter(self.warnings)
                # if the filter is 'default' or 'always', special-case the
                # warnings from the deprecated unittest methods to show them
                # no more than once per module, because they can be fairly
                # noisy.  The -Wd and -Wa flags can be used to bypass this
                # only when self.warnings is None.
                if self.warnings in ['default', 'always']:
                    warnings.filterwarnings('module',
                                            category=DeprecationWarning,
                                            message='Please use assert\w+ instead.')
            start_time = time.time()
            start_test_run = getattr(results, 'start_test_run', None)
            if start_test_run is not None:
                start_test_run()
            try:
                test(results)
            finally:
                stop_test_run = getattr(results, 'stopTestRun', None)
                if stop_test_run is not None:
                    stop_test_run()
            stop_time = time.time()
        time_taken = stop_time - start_time
        results.printErrors()
        if hasattr(results, 'separator2'):
            self.stream.writeln(results.separator2)
        run = results.testsRun
        self.stream.writeln("Ran %d test%s in %.3fs" %
                            (run, run != 1 and "s" or "", time_taken))
        self.stream.writeln()

        expected_fails = unexpected_successes = skipped = 0
        try:
            results_text = map(len, (results.expectedFailures,
                                     results.unexpectedSuccesses,
                                     results.skipped))
        except AttributeError:
            pass
        else:
            expected_fails, unexpected_successes, skipped = results_text

        results.set_test_time(time.strftime("%b %d %Y %H:%M:%S", time.gmtime(start_time)), format(time_taken, ".2f"))

        if self.report_path is not None:
            results.dump_results_into_json(self.report_path)

        info_results = []
        if not results.wasSuccessful():
            self.stream.write("FAILED")
            failed, error = len(results.failures), len(results.errors)
            if failed:
                info_results.append("failures=%d" % failed)
            if error:
                info_results.append("errors=%d" % error)
        else:
            self.stream.write("OK")
        if skipped:
            info_results.append("skipped=%d" % skipped)
        if expected_fails:
            info_results.append("expected failures=%d" % expected_fails)
        if unexpected_successes:
            info_results.append("unexpected successes=%d" % unexpected_successes)
        if info_results:
            self.stream.writeln(" (%s)" % (", ".join(info_results),))
        else:
            self.stream.write("\n")

        return results

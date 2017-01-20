#!/usr/bin/python3

import os
import sys
import subprocess
import shutil
import tempfile
from lxml import etree

ENCODE_LIMIT = 120
GRACE_TIME = 5

recordmydesktop_args = [
    "recordmydesktop",
    "--quick-subsampling",
    "--fps=60",
    "--no-sound",
    "--overwrite",
]


def getLoggerOutputPath(argv):
    outfile = None
    try:
        for logger in (argv[k + 1] for k, v in enumerate(argv) if v == "-o"):
            log = logger.split(',')[0]
            if os.path.isabs(log):
                outfile  = log
                break
    except IndexError as err:
        raise ValueError("Incorrect logger definition:\n{0}".format(argv)) from err
    return outfile


def sanitizeArgv(argv, failure_test):
    argv.append(failure_test)
    try:
        for k in (k for k, v in enumerate(argv) if v == "-o"):
            log = argv[k+1].split(',')[0]
            if os.path.isabs(log):
                argv.pop(k)
                argv.pop(k)
                break
    except IndexError as err:
        raise ValueError("Incorrect logger definition:\n{0}".format(argv)) from err
    return argv


def getRecordOutputPath(logger_outfile, failure_test):
    lo_basename = os.path.splitext(logger_outfile)[0]
    failure_test = str.replace(failure_test, '::', '-')
    return "{0}-{1}.ogv".format(os.path.splitext(logger_outfile)[0], failure_test)


def getFailingTests(logger_outfile):
    failures = set()

    tree = etree.parse(logger_outfile)
    root = tree.getroot()
    for failure in root.iterfind("testcase/failure"):
        failure_name = failure.getparent().attrib['name']
        failures.add(failure_name)

    return failures


def run_and_record_test_failure(argv, failure_test):
    logger_outfile = getLoggerOutputPath(argv)
    record_outfile = getRecordOutputPath(logger_outfile, failure_test)

    argv = sanitizeArgv(argv, failure_test)

    with tempfile.TemporaryDirectory() as tmpdir:
        # create a temporary file and close it to let recordmydesktop overwrite it
        tmpfd, tmpname = tempfile.mkstemp(dir=tmpdir, suffix=".ogv")
        os.close(tmpfd)
        recordmydesktop_args.extend(["--workdir={0}".format(tmpdir),
                                     "--output={0}".format(tmpname)])

        with subprocess.Popen(recordmydesktop_args, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, universal_newlines=True) as recorder:
            try:
                subprocess.check_call(argv)
            except subprocess.CalledProcessError as err:
                print("==== Record wrapper. Enconding ====")
                # stop recording, give ENCODE_LIMIT seconds to encode
                recorder.terminate()
                try:
                    recorder.wait(ENCODE_LIMIT)
                except subprocess.TimeoutExpired:
                    print("===== Recorder took too long to encode, recording will be incomplete =====")
                    recorder.terminate()
                    try:
                        recorder.wait(GRACE_TIME)
                    except subprocess.TimeoutExpired:
                        pass

                print("==== Record wrapper. Enconding is over. Return code: ", recorder.returncode)
                print(tmpname, " ", record_outfile)

                if recorder.returncode is 0:
                    # only store the file if recorder exited cleanly
                    shutil.move(tmpname, record_outfile)
            else:
                # abort the recording, test passed
                recorder.send_signal(subprocess.signal.SIGABRT)
                try:
                    recorder.wait(GRACE_TIME)
                except subprocess.TimeoutExpired:
                    pass
            finally:
                recorder.poll()
                # kill the recording if still running
                if recorder.returncode is None:
                    recorder.kill()
                    print("===== Had to kill recorder =====")
                elif recorder.returncode is not 0:
                    # only print recorder output if terminated unsuccessfully
                    print("===== Recorder error =====\nSTDOUT:\n{0}\n\nSTDERR:\n{1}".format(*recorder.communicate()))

if __name__ == "__main__":
    argv = sys.argv[1:]

    logger_outfile = getLoggerOutputPath(argv)
    returncode = 0

    try:
        # Run the tests without recording
        subprocess.check_call(argv)
    except subprocess.CalledProcessError as err:
        returncode = err.returncode
        failures = getFailingTests(logger_outfile)

        # We now run each failing test and eventually record it if it fails again
        argv.pop()
        for failure in failures:
            run_and_record_test_failure(argv[:], failure)

    sys.exit(returncode)

#!/usr/bin/python3

import os
import sys
import subprocess
import shutil
import tempfile

ENCODE_LIMIT=60
GRACE_TIME=5

recordmydesktop_args = [
    "recordmydesktop",
    "--quick-subsampling",
    "--fps=60",
    "--no-sound",
    "--overwrite",
]

if __name__ == "__main__":
    """
    This script wraps qmltestrunner, recording the screen as the test runs
    with recordmydesktop. Maximum encoding time is {0}s, the process is
    interrupted after that time. If the test succeeds, recording is aborted
    and no video produced.
    Output video file name is derived from the first logger option in the
    "-o /file/path,format" format with *absolute* paths, the file is saved
    next to the test log file with the extension ".ogv", falling back to
    "qmltest.ogv" in the current directory.
    """
    
    argv = sys.argv.copy()
    argv[0] = "qmltestrunner"
    
    outfile = os.path.join(os.curdir, "qmltest.ogv")   
    returncode = 0

    try:
        for logger in (argv[k+1] for k, v in enumerate(argv) if v == "-o"):
            log = logger.split(',')[0]
            if os.path.isabs(log):
                outfile = "{0}.ogv".format(os.path.splitext(log)[0])
                break
    except IndexError as err:
        raise ValueError("Missing logger definition:\n{0}".format(argv)) from err


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
                # store the exit code to return
                returncode = err.returncode
                
                # stop recording, give 60 seconds to encode
                recorder.terminate()
                recorder.wait(ENCODE_LIMIT)
                if recorder.returncode is None:
                    print("===== Recorder took too long to encode, recording will be incomplete =====")
                    recorder.terminate()
                    recorder.wait(GRACE_TIME)
                if recorder.returncode is 0:
                    # only store the file if recorder exited cleanly
                    shutil.move(tmpname, outfile)
            else:
                # abort the recording, test passed  
                recorder.send_signal(subprocess.signal.SIGABRT)
                recorder.wait(GRACE_TIME)
            finally:
                recorder.poll()
                # kill the recording if still running
                if recorder.returncode is None:
                    recorder.kill()
                    print("===== Had to kill recorder =====")
                elif recorder.returncode is not 0:
                    # only print recorder output if terminated successfully
                    print("===== Recorder error =====\nSTDOUT:\n{0}\n\nSTDERR:\n{1}".format(*recorder.communicate()))

    sys.exit(returncode)
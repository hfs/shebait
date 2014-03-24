shebait.sh – SHell BAsed Integration Testing
============================================

Runs a series of tests, which are written as shell scripts.

Run all tests in the subdirectory 'tests'. Their exit code indicates success (0), test failure (1) or other errors (>1).

Only files whose names do *not* contain a dot '.' are executed. This allows you to disable tests by giving them a file name suffix or to store helper functions in .sh files.

During the tests the currently running test name is displayed. The test name is the name of the executable, with leading digits removed and underscores replaced by whitespace.

In the end a short summary statistic is displayed. Tests results with details and command outputs are stored in `results/test-results.xml` in JUnit's XML format. This allows to display the test results in build servers like Jenkins.

Example
-------

    $ ls tests
    001_Prepare_the_environment          003_The_long_running_test_itself
    002_Check_if_everything_is_in_place  004_Evaluate_the_results
    
    $ ./shebait.sh 
    [PASS] Prepare the environment
    [FAIL] Check if everything is in place
    [    ] The long running test itself█
    
    … time passes …
    
    [PASS] The long running test itself
    [PASS] Evaluate the results
    
    Summary: 3 of 4 tests passed in 3058ms, 1 failed, 0 error(s)

Usage
-----

Put your tests in shell scripts and declare them with e.g. `#!/bin/bash -e`. This way any error will make the test fail fast.

Write many small test rather than one big one.

The tests are executed in directory order.

During execution standard output and error of the tests are silenced. They are redirected to the result XML file instead. Check this file to find out what went wrong. You can `set -x` in your test to see which commands were executed.

There is no provided test set-up or tear-down. You have to start and stop any services you want to test yourself and clean up temporary files.

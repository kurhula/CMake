include(RunCTest)
set(RunCMake_TEST_TIMEOUT 60)

unset(ENV{CTEST_PARALLEL_LEVEL})
unset(ENV{CTEST_OUTPUT_ON_FAILURE})

set(CASE_CTEST_TEST_ARGS "")
set(CASE_CTEST_TEST_LOAD "")

function(run_ctest_test CASE_NAME)
  set(CASE_CTEST_TEST_ARGS "${ARGN}")
  run_ctest(${CASE_NAME})
endfunction()

run_ctest_test(TestQuiet QUIET)

# Tests for the 'Test Load' feature of ctest
#
# Spoof a load average value to make these tests more reliable.
set(ENV{__CTEST_FAKE_LOAD_AVERAGE_FOR_TESTING} 5)

# Verify that new tests are started when the load average falls below
# our threshold.
run_ctest_test(TestLoadPass TEST_LOAD 6)

# Verify that new tests are not started when the load average exceeds
# our threshold and that they then run once the load average drops.
run_ctest_test(TestLoadWait TEST_LOAD 2)

# Verify that when an invalid "TEST_LOAD" value is given, a warning
# message is displayed and the value is ignored.
run_ctest_test(TestLoadInvalid TEST_LOAD "ERR1")

# Verify that new tests are started when the load average falls below
# our threshold.
set(CASE_CTEST_TEST_LOAD 7)
run_ctest_test(CTestTestLoadPass)

# Verify that new tests are not started when the load average exceeds
# our threshold and that they then run once the load average drops.
set(CASE_CTEST_TEST_LOAD 4)
run_ctest_test(CTestTestLoadWait)

# Verify that when an invalid "CTEST_TEST_LOAD" value is given,
# a warning message is displayed and the value is ignored.
set(CASE_CTEST_TEST_LOAD "ERR2")
run_ctest_test(CTestTestLoadInvalid)

# Verify that the "TEST_LOAD" value has higher precedence than
# the "CTEST_TEST_LOAD" value
set(CASE_CTEST_TEST_LOAD "ERR3")
run_ctest_test(TestLoadOrder TEST_LOAD "ERR4")

unset(ENV{__CTEST_FAKE_LOAD_AVERAGE_FOR_TESTING})
unset(CASE_CTEST_TEST_LOAD)

function(run_TestChangeId)
  set(CASE_TEST_PREFIX_CODE [[
    set(CTEST_CHANGE_ID "<>1")
  ]])

  run_ctest(TestChangeId)
endfunction()
run_TestChangeId()

function(run_TestOutputSize)
  set(CASE_CTEST_TEST_ARGS EXCLUDE RunCMakeVersion)
  set(CASE_TEST_PREFIX_CODE [[
set(CTEST_CUSTOM_MAXIMUM_PASSED_TEST_OUTPUT_SIZE 10)
set(CTEST_CUSTOM_MAXIMUM_FAILED_TEST_OUTPUT_SIZE 12)
  ]])
  set(CASE_CMAKELISTS_SUFFIX_CODE [[
add_test(NAME PassingTest COMMAND ${CMAKE_COMMAND} -E echo PassingTestOutput)
add_test(NAME FailingTest COMMAND ${CMAKE_COMMAND} -E no_such_command)
  ]])

  run_ctest(TestOutputSize)
endfunction()
run_TestOutputSize()

run_ctest_test(TestRepeatBad1 REPEAT UNKNOWN:3)
run_ctest_test(TestRepeatBad2 REPEAT UNTIL_FAIL:-1)

function(run_TestRepeat case)
  set(CASE_CTEST_TEST_ARGS EXCLUDE RunCMakeVersion ${ARGN})
  string(CONCAT CASE_CMAKELISTS_SUFFIX_CODE [[
add_test(NAME testRepeat
  COMMAND ${CMAKE_COMMAND} -D COUNT_FILE=${CMAKE_CURRENT_BINARY_DIR}/count.cmake
                           -P "]] "${RunCMake_SOURCE_DIR}/TestRepeat${case}" [[.cmake")
set_property(TEST testRepeat PROPERTY TIMEOUT 5)
  ]])

  run_ctest(TestRepeat${case})
endfunction()
run_TestRepeat(UntilFail REPEAT UNTIL_FAIL:3)
run_TestRepeat(UntilPass REPEAT UNTIL_PASS:3)
run_TestRepeat(AfterTimeout REPEAT AFTER_TIMEOUT:3)

# test --stop-on-failure
function(run_stop_on_failure)
  set(CASE_CTEST_TEST_ARGS EXCLUDE RunCMakeVersion)
  set(CASE_CMAKELISTS_SUFFIX_CODE [[
add_test(NAME StoppingTest COMMAND ${CMAKE_COMMAND} -E false)
add_test(NAME NotRunTest COMMAND ${CMAKE_COMMAND} -E true)
  ]])

  run_ctest_test(stop-on-failure STOP_ON_FAILURE)
endfunction()
run_stop_on_failure()

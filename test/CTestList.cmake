# Set location of gold files according to system/compiler/compiler_version
set(FCOMPARE_GOLD_FILES_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/AMR-WindGoldFiles/${CMAKE_SYSTEM_NAME}/${CMAKE_CXX_COMPILER_ID}/${CMAKE_CXX_COMPILER_VERSION})

if(AMR_WIND_TEST_WITH_FCOMPARE)
  message(STATUS "Test golds directory for fcompare: ${FCOMPARE_GOLD_FILES_DIRECTORY}")
endif()

# Have CMake discover the number of cores on the node
include(ProcessorCount)
ProcessorCount(PROCESSES)

#=============================================================================
# Functions for adding tests / Categories of tests
#=============================================================================

# Standard regression test
function(add_test_r TEST_NAME NP)
    # Set variables for respective binary and source directories for the test
    set(CURRENT_TEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test_files/${TEST_NAME})
    set(CURRENT_TEST_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/test_files/${TEST_NAME})
    # Gold files should be submodule organized by machine and compiler (these are output during configure)
    set(PLOT_GOLD ${FCOMPARE_GOLD_FILES_DIRECTORY}/${TEST_NAME}/plt00010)
    # Test plot is currently expected to be after 10 steps
    set(PLOT_TEST ${CURRENT_TEST_BINARY_DIR}/plt00010)
    # Find fcompare
    if(AMR_WIND_TEST_WITH_FCOMPARE)
      set(FCOMPARE ${CMAKE_BINARY_DIR}/submods/amrex/Tools/Plotfile/fcompare)
    endif()
    # Make working directory for test
    file(MAKE_DIRECTORY ${CURRENT_TEST_BINARY_DIR})
    # Gather all files in source directory for test
    file(GLOB TEST_FILES "${CURRENT_TEST_SOURCE_DIR}/*")
    # Copy files to test working directory
    file(COPY ${TEST_FILES} DESTINATION "${CURRENT_TEST_BINARY_DIR}/")
    # Set some default runtime options for all tests in this category
    set(RUNTIME_OPTIONS "time.max_step=10 amr.plot_file=plt amr.checkpoint_files_output=0 amr.plot_files_output=1 amrex.throw_exception=1 amrex.signal_handling=0")
    # Use fcompare to test diffs in plots against gold files
    if(AMR_WIND_TEST_WITH_FCOMPARE)
      set(FCOMPARE_COMMAND "&& ${FCOMPARE} ${PLOT_GOLD} ${PLOT_TEST}")
    endif()
    if(AMR_WIND_ENABLE_MPI)
      set(MPI_COMMANDS "${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${NP} ${MPIEXEC_PREFLAGS}")
    else()
      unset(MPI_COMMANDS)
    endif()
    # Add test and actual test commands to CTest database
    add_test(${TEST_NAME} sh -c "${MPI_COMMANDS} ${CMAKE_BINARY_DIR}/${amr_wind_exe_name} ${MPIEXEC_POSTFLAGS} ${CURRENT_TEST_BINARY_DIR}/${TEST_NAME}.i ${RUNTIME_OPTIONS} > ${TEST_NAME}.log ${FCOMPARE_COMMAND}")
    # Set properties for test
    set_tests_properties(${TEST_NAME} PROPERTIES
                         TIMEOUT 5400
                         PROCESSORS ${NP}
                         WORKING_DIRECTORY "${CURRENT_TEST_BINARY_DIR}/"
                         LABELS "regression"
                         ATTACHED_FILES_ON_FAIL "${CURRENT_TEST_BINARY_DIR}/${TEST_NAME}.log")
endfunction(add_test_r)

# Regression tests excluded from CI
function(add_test_re TEST_NAME NP)
    add_test_r(${TEST_NAME} ${NP})
    set_tests_properties(${TEST_NAME} PROPERTIES LABELS "regression;no_ci")
endfunction(add_test_re)

# Regression test and excluded from CI with dependency
function(add_test_red TEST_NAME NP TEST_DEPENDENCY)
    add_test_re(${TEST_NAME} ${NP})
    set_tests_properties(${TEST_NAME} PROPERTIES FIXTURES_REQUIRED fixture_${TEST_DEPENDENCY})
    set_tests_properties(${TEST_DEPENDENCY} PROPERTIES FIXTURES_SETUP fixture_${TEST_DEPENDENCY})
endfunction(add_test_red)

# Standard unit test
function(add_test_u TEST_NAME NP)
    # Set variables for respective binary and source directories for the test
    set(CURRENT_TEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test_files/${TEST_NAME})
    set(CURRENT_TEST_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/test_files/${TEST_NAME})
    # Make working directory for test
    file(MAKE_DIRECTORY ${CURRENT_TEST_BINARY_DIR})
    if(AMR_WIND_ENABLE_MPI)
      set(MPI_COMMANDS "${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${NP} ${MPIEXEC_PREFLAGS}")
    else()
      unset(MPI_COMMANDS)
    endif()
    # Add test and commands to CTest database
    add_test(${TEST_NAME} sh -c "${MPI_COMMANDS} ${CMAKE_BINARY_DIR}/${amr_wind_unit_test_exe_name}")
    # Set properties for test
    set_tests_properties(${TEST_NAME} PROPERTIES
                         TIMEOUT 500
                         PROCESSORS ${NP}
                         WORKING_DIRECTORY "${CURRENT_TEST_BINARY_DIR}/"
                         LABELS "unit")
endfunction(add_test_u)

#=============================================================================
# Unit tests
#=============================================================================
add_test_u(unit_tests 1)

#=============================================================================
# Regression tests
#=============================================================================
add_test_r(abl_godunov 4)
add_test_r(boussinesq_bubble_godunov 4)
add_test_r(tgv_godunov 4)
add_test_r(abl_mol 4)

#=============================================================================
# Regression tests excluded from CI
#=============================================================================
add_test_re(tgv_mol 4)
add_test_re(boussinesq_bubble_mol 4)
add_test_re(rayleigh_taylor_godunov 4)
add_test_re(rayleigh_taylor_mol 4)
add_test_re(abl_godunov_plm 4)
add_test_re(abl_godunov_explicit 4)
add_test_re(abl_godunov_cn 4)
add_test_re(abl_mol_explicit 4)
add_test_re(abl_mol_cn 4)
add_test_re(tgv_godunov_plm 4)
add_test_re(abl_godunov_static_refinement 4)
if(AMR_WIND_ENABLE_MASA)
  add_test_re(mms_godunov 4)
  add_test_re(mms_godunov_plm 4)
  add_test_re(mms_mol 4)
endif()

#=============================================================================
# Regression tests excluded from CI with a test dependency
#=============================================================================
add_test_red(abl_godunov_restart 4 abl_godunov)

#=============================================================================
# Verification tests
#=============================================================================

#=============================================================================
# Performance tests
#=============================================================================


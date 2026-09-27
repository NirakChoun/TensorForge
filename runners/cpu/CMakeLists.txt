# Plain C++ executable (no MLIR libraries): it only dlopen()s compiled kernels.
add_executable(tforge-cpu-bench tforge-cpu-bench.cpp)
set_target_properties(tforge-cpu-bench PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
  # Export the allocation hooks so loaded kernels resolve them here.
  ENABLE_EXPORTS ON)
target_compile_options(tforge-cpu-bench PRIVATE -O2)
target_link_libraries(tforge-cpu-bench PRIVATE ${CMAKE_DL_LIBS})

add_subdirectory(Dialect)

set(LLVM_TARGET_DEFINITIONS Passes.td)
mlir_tablegen(Passes.h.inc -gen-pass-decls -name TForge)
add_public_tablegen_target(MLIRTForgePassIncGen)

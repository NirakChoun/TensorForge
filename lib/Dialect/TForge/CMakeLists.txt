add_mlir_dialect_library(MLIRTForge
  TForgeDialect.cpp
  TForgeOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include/TensorForge/Dialect/TForge

  DEPENDS
  MLIRTForgeOpsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRSideEffectInterfaces
)

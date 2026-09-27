add_mlir_conversion_library(MLIRTForgeToLinalg
  TForgeToLinalg.cpp

  DEPENDS
  MLIRTForgePassIncGen

  LINK_LIBS PUBLIC
  MLIRTForge
  MLIRArithDialect
  MLIRLinalgDialect
  MLIRTensorDialect
  MLIRPass
  MLIRTransformUtils
)

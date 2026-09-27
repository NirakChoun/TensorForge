add_mlir_library(MLIRTForgeTransforms
  TileAndFuse.cpp

  DEPENDS
  MLIRTForgePassIncGen

  LINK_LIBS PUBLIC
  MLIRAffineDialect
  MLIRArithDialect
  MLIRFuncDialect
  MLIRLinalgDialect
  MLIRLinalgTransforms
  MLIRSCFDialect
  MLIRSCFTransforms
  MLIRTensorDialect
  MLIRTensorTransforms
  MLIRTilingInterface
)

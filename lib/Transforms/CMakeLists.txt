add_mlir_library(MLIRTForgeTransforms
  TileAndFuse.cpp
  Vectorize.cpp
  Gpu.cpp

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
  MLIRVectorDialect
  MLIRVectorTransforms
  MLIRMemRefDialect
  MLIRBufferizationDialect
  MLIRGPUDialect
  MLIRLLVMDialect
  MLIRParser
  MLIRTransformDialect
  MLIRTransformDialectTransforms
)

add_mlir_library(MLIRTForgeTransforms
  TileAndFuse.cpp
  Vectorize.cpp
  Gpu.cpp
  PrintIR.cpp

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
  MLIRMemRefTransforms
  MLIRBufferizationDialect
  MLIRGPUDialect
  MLIRLLVMDialect
  MLIRParser
  MLIRTransformDialect
  MLIRTransformDialectTransforms
)

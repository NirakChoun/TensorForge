# -*- Python -*-
import os

import lit.formats
from lit.llvm import llvm_config

config.name = "TENSORFORGE"
config.test_format = lit.formats.ShTest(execute_external=False)
config.suffixes = [".mlir"]
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.path.join(config.tforge_obj_root, "test")
config.excludes = ["CMakeLists.txt", "lit.cfg.py", "lit.site.cfg.py"]

llvm_config.with_system_environment(["HOME", "TMP", "TEMP"])
# Provides FileCheck, not, count from llvm_tools_dir.
llvm_config.use_default_substitutions()

tool_dirs = [config.tforge_tools_dir, config.llvm_tools_dir]
llvm_config.add_tool_substitutions(["tensorforge-opt"], tool_dirs)
llvm_config.with_environment("PATH", config.llvm_tools_dir, append_path=True)

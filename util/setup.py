import os
import sys
from distutils.core import setup, Extension

owd = os.getcwd()
print(owd)
#os.chdir("util")

sys.argv.append('build_ext')
sys.argv.append('--inplace')

module = Extension('util', sources=['util.c'], extra_compile_args=['/openmp'])
setup(name='util', version='1.0', ext_modules=[module])

os.chdir(owd)

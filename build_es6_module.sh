#!/bin/sh

export COMPILER_SOURCE=kaitai_struct_compiler/js/target/scala-2.12/kaitai-struct-compiler-js-opt.js
export COMPILER_TARGET=kaitai-struct-compiler.mjs

echo
echo updating kaitai_struct_compiler submodule
echo

rm -rf kaitai_struct_compiler
git submodule init
git submodule update --remote --merge

# fix @JSExport name
sed -zi 's/annotation\.JSExport\n\n@JSExport/annotation._\n\n@JSExportTopLevel("KaitiaiStructCompiler")/' \
    kaitai_struct_compiler/js/src/main/scala/io/kaitai/struct/MainJs.scala

echo
echo compile KSC
echo

cd kaitai_struct_compiler
export GIT_COMMIT=$(git log -1 --format=%h)
export GIT_DATE_ISO=$(TZ=UTC git log -1 --date=iso-strict-local --format=%cd)
export GIT_DATE=$(TZ=UTC git log -1 --date=format-local:%Y%m%d.%H%M%S --format=%cd)
export KAITAI_STRUCT_VERSION=0.9-SNAPSHOT${GIT_DATE}.${GIT_COMMIT}
sbt +"set scalaJSLinkerConfig in compilerJS ~= (_.withModuleKind(ModuleKind.ESModule).withESFeatures(_.withUseECMAScript2015(true)))" fullOptJS
cd ..

echo
echo copy to root
echo

echo "/* kaitai_struct_compiler ${KAITAI_STRUCT_VERSION} */\n" > ${COMPILER_TARGET}
sed -z 's/\n\n\n*/\n\n/g' ${COMPILER_SOURCE} >> ${COMPILER_TARGET}

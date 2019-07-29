#!/bin/sh

export COMPILER_SOURCE=kaitai_struct_compiler/js/target/scala-2.12/kaitai-struct-compiler-js-opt.js
export COMPILER_TARGET=kaitai-struct-compiler.mjs

echo update kaitai_struct_compiler submodule
rm -rf kaitai_struct_compiler
git submodule update
git submodule foreach git pull origin master

# update scala js
sed -i 's/"sbt-scalajs" % "0.6.21"/"sbt-scalajs" % "0.6.28"/' kaitai_struct_compiler/project/plugins.sbt

# fix @JSExport name
sed -zi 's/annotation\.JSExport\n\n@JSExport/annotation._\n\n@JSExportTopLevel("KaitiaiStructCompiler")/' \
    kaitai_struct_compiler/js/src/main/scala/io/kaitai/struct/MainJs.scala

echo compile ${COMPILER_SOURCE}
cd kaitai_struct_compiler
export GIT_COMMIT=$(git log -1 --format=%h)
export GIT_DATE_ISO=$(TZ=UTC git log -1 --date=iso-strict-local --format=%cd)
export GIT_DATE=$(TZ=UTC git log -1 --date=format-local:%Y%m%d.%H%M%S --format=%cd)
export KAITAI_STRUCT_VERSION=0.9-SNAPSHOT${GIT_DATE}.${GIT_COMMIT}
sbt +"set scalaJSLinkerConfig in compilerJS ~= (_.withModuleKind(ModuleKind.ESModule))" fullOptJS
cd ..

echo copy to ${COMPILER_TARGET}
echo "/* kaitai_struct_compiler ${KAITAI_STRUCT_VERSION} */\n" > ${COMPILER_TARGET}
sed -z 's/\n\n\n*/\n\n/g' ${COMPILER_SOURCE} >> ${COMPILER_TARGET}

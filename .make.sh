#!/bin/sh

cat ./src/Makefile > ./Makefile;

cat Makefile | grep "define DOCKERFILE_CONTENT" >/dev/null;
if [ "$?" = "0" ]; then 
  sed -i '/define DOCKERFILE_CONTENT/,/export DOCKERFILE_CONTENT/d' ./Makefile;
fi;
printf -- "\
define DOCKERFILE_CONTENT
$(sed -e 's|\$|$$|g' ./src/Dockerfile)
endef
export DOCKERFILE_CONTENT
" >> ./Makefile

cat Makefile | grep "define AUTO_RUN_TESTS_CONTENT" >/dev/null;
if [ "$?" = "0" ]; then 
  sed -i '/define AUTO_RUN_TESTS_CONTENT/,/export AUTO_RUN_TESTS_CONTENT/d' ./Makefile;
fi;
printf -- "\
define AUTO_RUN_TESTS_CONTENT
$(sed -e 's|\\|\\\\\\\\|g' -e 's|%|%%|g' ./src/.scripts/auto-run.py)
endef
export AUTO_RUN_TESTS_CONTENT
" >> ./Makefile

cat Makefile | grep "define BASH_PROFILE_CONTENT" >/dev/null;
if [ "$?" = "0" ]; then 
  sed -i '/define BASH_PROFILE_CONTENT/,/export BASH_PROFILE_CONTENT/d' ./Makefile;
fi;
printf -- "define BASH_PROFILE_CONTENT
$(sed -e 's|\$|$$|g' -e 's|\\a|\\\\\\\\a|g' -e 's|\\n|\\\\\\\\n|g' -e 's|%|%%|g' ./src/.scripts/.bash_profile)
endef
export BASH_PROFILE_CONTENT
" >> ./Makefile

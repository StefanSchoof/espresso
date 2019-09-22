#!/bin/bash -e

function writeDevopsVar {
  options=""
  if [ $3 ]
  then
    options=";issecret=true"
  fi
  if [ $4 ]
  then
    options="$options;isOutput=true"
  fi
  echo "##vso[task.setvariable variable=$1$options]$2"
}

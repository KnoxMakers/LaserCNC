#!/bin/bash

KM_EXTENSIONS_DIR='./inkscape-extensions'
INKSCAPE_EXTENSIONS_DIR=$HOME/'.config/inkscape/extensions/'

echo 'Installing KnoxMakers LaserCNC extension for Inkscape...'
echo ''

if [ ! -d "$INKSCAPE_EXTENSIONS_DIR" ]
then
  echo 'Inkscape extensions directory does not exists, creating extensions directory...'
  echo ''
  mkdir -p $INKSCAPE_EXTENSIONS_DIR
  echo 'Finished creating extensions directory, copying LaserCNC extension files...'
  echo ''
else
  echo 'Extensions directory exists, copying LaserCNC extension files...'
  echo ''
fi

yes | cp -rf $KM_EXTENSIONS_DIR/* $INKSCAPE_EXTENSIONS_DIR

echo 'SUCCESS!!! Installed KnoxMakers LaserCNC extension for Inkscape!'
echo ''


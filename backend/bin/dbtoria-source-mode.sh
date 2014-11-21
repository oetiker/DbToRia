#!/bin/sh
export QX_SRC_MODE=1
export MOJO_MODE=development
export MOJO_LOG_LEVEL=debug
exec ./dbtoria.pl prefork --listen 'http://*:4542'

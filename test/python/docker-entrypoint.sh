#!/bin/sh


PYTHON_FILE="$1"

# Install pika module
pip install pika==1.1.0

# Check specified file exist
[ -f $PYTHON_FILE ] || {
    echo "Cannot find the file $PYTHON_FILE"
    exit 1
}

# Use exec to run on same shell as pid 0
exec python $PYTHON_FILE

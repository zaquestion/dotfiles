#!/bin/bash

if [[ ${2: -4} != ".swp" && ${2: -5} != ".swpx" && $2 != "tags" ]]; then
        if [[ "${1##$projects/go}" != "$1" ]]; then
        else
                ctags -R --exclude=$projects/go -f $projects/tags $projects/ &> /dev/null &
        fi
else
        echo "file ignored"
fi

#!/bin/bash

if [[ ${2: -4} != ".swp" && ${2: -5} != ".swpx" && $2 != "tags" ]]; then
        if [[ "${1##$projects/go}" != "$1" ]]; then
                echo "gotags updated"
                gotags -R=true -f $projects/go/tags $projects/go
        else    
                echo "ctags updated"
                ctags -R --exclude=$projects/go -f $projects/tags $projects/
        fi      
else
        echo "file ignored"
fi

#!/bin/bash
if test -f $1
then
	stat --format="%a %n" $1	
else
	exit 127
fi

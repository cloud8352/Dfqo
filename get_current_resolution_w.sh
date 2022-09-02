#!/bin/sh

str=$(xrandr --current)
str=$(echo ${str#*current})
str=$(echo ${str%, maximum*})
echo ${str% x*}
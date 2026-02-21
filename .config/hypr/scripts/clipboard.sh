#!/bin/bash

sleep 2

wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
cliphist load


#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v No.info.on.package.*found \
    | grep -v Variable.*is.never.read \
    | grep -v Unknown.subcommand..home..to..file \
    | grep -v Found.constant.*which.is.also.a.variable
du -sh .git
ls -sh .*.str
clc -s -l tcl
str s
git st

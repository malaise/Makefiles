HOST            := $(shell uname -s)
TEMPLATES       := $(HOME)/Makefiles

RM              := rm -rf
LN              := ln -fs
TOUCH           := touch
MKDIR           := mkdir -p

LIB             := lib_$(HOST)
BIN             := bin_$(HOST)
DIRS            := $(LIB) $(BIN)

include $(TEMPLATES)/path.mk


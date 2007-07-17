HOST            := $(shell uname -s)
TEMPLATES       := $(HOME)/Makefiles

RM              := rm -f
LN              := ln -fs
TOUCH           := touch
MKDIR           := mkdir -p

LIB             := lib_$(HOST)
BIN             := bin_$(HOST)
DIRS            := $(LIB) $(BIN)

NOPRTDIR        := --no-print-directory

include $(TEMPLATES)/path.mk


ifdef CPATH
CPATHD          := $(CPATH:%=%/$(LIB))
CPATHL          := $(CPATHD:%=-L%)
endif


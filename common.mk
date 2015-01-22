HOST            := $(shell uname -s)
TEMPLATES       := $(if $(MAKFILES_DIR), $(MAKFILES_DIR), $(HOME)/Makefiles)

RM              := /bin/rm -f
CP              := /bin/cp -pPf
LN              := /bin/ln -fs
TOUCH           := /bin/touch
MKDIR           := /bin/mkdir -p
CHMOD_AR        := /bin/chmod a+r
CHMOD_ARX       := /bin/chmod a+rx
ECHO            := /bin/echo
SED             := /bin/sed

LIB             := lib_$(HOST)
BIN             := bin_$(HOST)
DIRS            := $(LIB) $(BIN)

NOPRTDIR        := --no-print-directory
SILENT          := --silent

include $(TEMPLATES)/path.mk


ifdef CPATH
CPATHD          := $(CPATH:%=%/$(LIB))
CPATHL          := $(CPATHD:%=-L%)
endif


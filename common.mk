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

LIB             := lib
DIRS            := $(LIB)

NOPRTDIR        := --no-print-directory
SILENT          := --silent

include $(TEMPLATES)/path.mk


ifdef CPATH
CPATHD          := $(CPATH:%=%/$(LIB))
CPATHL          := $(CPATHD:%=-L%)
endif

ifdef PCRE
PCRE_SLIBS := posix2pcre $(PCRE_LIBS)
PCRE_ALIBS := $(CPATHD)/libposix2pcre.a $(PCRE_LIBS:%=$(PCRE_LIB)/lib%.a)
endif

UTILS_SLIBS := cutil
UTILS_ALIBS := $(CPATHD)/libcutil.a

X11_SLIBS := x_mng $(UTILS_SLIBS) X11
X11_ALIBS := $(CPATHD)/libx_mng.a $(UTILS_ALIBS) -lX11


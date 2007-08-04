ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATLSFLAG     := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
endif

GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato -gnatE -fstack-check
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATLSFLAG     := -I$(LIB) $(GNATLSFLAG)
GNATHTMLOPT    ?= -d

GNATHTML       := $(GNATPATH)/gnathtml.pl $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
GNATLS         := $(GNATPATH)/gnatls $(GNATLSFLAG)
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe

include $(TEMPLATES)/units.mk
BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .ads .adb .o .ali .stat
.PHONY : all alis libs afpx ls
.SECONDARY : $(BEXES)

$(LIB)/%.ali $(LIB)/%.o :: %.adb
	@cd $(LIB); \
	$(ADA) ../$(<F) $(GARGS) -cargs $(CARGS)

all : $(DIRS) alis libs $(EXES) afpx

include $(TEMPLATES)/post.mk

# Static and dynamic exe
$(BIN)/%.stat : $(DIRS) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F:%.stat=%) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -static \
	  -largs $(LARGS_$(@F)) $(LARGS) -lm

$(BIN)/% : $(DIRS) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -shared \
	  -largs $(CPATHL) $(CLIBS_$(@F):%=-l%) $(CLIBS:%=-l%) \
                           $(LARGS_$(@F)) $(LARGS)

# Make ali in LIB
alis : $(LIB)
	@for file in $(UNITS) ; do \
	  if [ ! -f $(LIB)/$$file.ali ] ; then \
	    $(TOUCH) $(LIB)/$$file.ali; \
	  fi; \
	done

# Compile local libraries (no exes)
ifdef LIBS
libs : $(LIB)
	@cd $(LIB); \
	for file in $(LIBS); do \
	  if [ -f ../$$file.adb ] ; then \
	    $(ADA) ../$$file.adb $(GARGS) -cargs $(CARGS); \
	  else \
	    $(ADA) ../$$file.ads $(GARGS) -cargs $(CARGS); \
	  fi; \
	done; \
	exit 0
else
libs :;
endif

# Make a stub of body from spec
%.adb : %.ads
	@if [ ! -f $@ ] ; then \
	  echo "gnatstub $<"; \
	  PATH=$(GNATPATH):$(PATH); \
	  $(GNATSTUB) $<; \
	  if [ $$? -ne 0 ] ; then \
	    exit 1; \
	  fi; \
	  if [ ! -f $@ ] ; then \
	    exit 0; \
	  fi; \
	  type astub > /dev/null 2>&1; \
	  if [ $$? -eq 0 ] ; then \
	    rm -rf $@; \
	    echo "astub $<"; \
	    astub $<; \
	  else \
	    echo "Warning: astub not found, keeping gnatsub result."; \
	  fi; \
	else \
	  $(TOUCH) $@; \
	fi

lsdep :
	@type alsdep > /dev/null 2>&1; \
	if [ $$? -ne 0 ] ; then \
	  echo "Error: adep not found."; \
	else \
	  export ADAVIEW="$(ADAVIEW)"; \
	  export GNATLS="$(GNATLS)"; \
	  export LIB="$(LIB)"; \
	  if [ "$(OF)" != "" ] ; then \
	    alsdep "$(OF)"; \
	  else \
	    alsdep $(LIBS) $(EXES); \
	  fi; \
	fi


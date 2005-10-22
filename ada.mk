ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif
GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATHTMLOPT    ?= -d

GNATPATH       := /usr/local/gnat/bin
GNATHTML       := $(GNATPATH)/gnathtml $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe

ifdef CPATH
CPATH          := $(CPATH:%=-L%/$(LIB))
endif

include $(TEMPLATES)/units.mk
BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .ads .adb .o .ali .stat
.PHONY : all alis libs afpx
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
	  -largs $(CPATH) $(CLIBS_$(@F):%=-l%) $(CLIBS:%=-l%) \
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


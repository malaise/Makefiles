ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif
GNATMAKEFLAG   := $(GNATMAKEFLAG) -i
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATHTMLOPT    ?= -d

GNATHTML       := gnathtml $(GNATHTMLFLAG)
GNATMAKE       := gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
ADA            := $(GNATMAKE) -c

ifdef CPATH
CPATH          := $(CPATH:%=-L%/$(LIB))
endif

UNITS ?= $(shell $(TEMPLATES)/units.sh)

.SUFFIXES : .ads .adb .o .ali .stat
.PHONY : all alis libs afpx

$(LIB)/%.ali $(LIB)/%.o : %.adb
	@cd $(LIB); \
	$(ADA) ../$(<F)

all : $(DIRS) alis libs $(EXES) afpx

include $(TEMPLATES)/post.mk

# Static and dynamic exe
$(BIN)/%.stat : $(BIN) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F:%.stat=%) -o ../$@ \
	  -largs $(LARGS_$(@F)) $(LARGS)

$(BIN)/% : $(BIN) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F) -o ../$@ \
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
libs :
	@cd $(LIB); \
	for file in $(LIBS); do \
	  if [ -f ../$$file.adb ] ; then \
	    $(ADA) ../$$file.adb; \
	  else \
	    $(ADA) ../$$file.ads; \
	  fi; \
	done
else
libs :;
endif



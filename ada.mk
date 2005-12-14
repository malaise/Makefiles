ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif
GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATHTMLOPT    ?= -d

GNATHTML       := $(GNATPATH)/gnathtml.pl $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
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

# Make a stub of body from spec
%.adb : %.ads
	@if [ ! -f $@ ] ; then \
	  echo "gnatstub $<"; \
	  PATH=$(GNATPATH):$(PATH); \
	  $(GNATSTUB) $<; \
	  if [ ! -f $@ ] ; then \
	    echo "Error: Gnatsub failed."; \
	    exit 1; \
	  fi; \
	  cp $@ $@.tmp; \
	  type asubst > /dev/null 2>&1; \
	  if [ $$? -eq 0 ] ; then \
	    asubst "^(  )*--.*\n(  )*--.*\n(  )*--.*\n\n" "\R03\n" $@.tmp  > /dev/null; \
	  else \
	    echo "Warning: asubst not found, partial processing."; \
	  fi; \
	  awk ' \
	    BEGIN { \
	      IN_PROC = 0; \
	    } \
	    ( (IN_PROC == 0) && (NF == 2) \
	      && ( ($$1 == "procedure") || ($$1 == "function") ) ) { \
	      TABS = ""; for (I = 0; I <= length($$0); I++) TABS = TABS " "; \
	      PREV = $$0; \
	      IN_PROC = 1; \
	      next; \
	    } \
	    (IN_PROC != 0) { \
	      gsub ("^ *", ""); \
	      if ($$1 == "is") { \
	        print PREV " " $$0; \
	        IN_PROC = 0; \
	        next; \
	      } \
	      if (IN_PROC == 1) { \
	        PREV = PREV " " $$0; \
	        IN_PROC = 2; \
	        next; \
	      } else { \
	        print PREV; \
	        PREV = TABS " " $$0; \
	        next; \
	      } \
	    } \
	    { \
	      print; \
	    } \
	    END { \
	      print ""; \
	    } \
	  ' <$@.tmp >$@; \
	  rm $@.tmp; \
	else \
	  $(TOUCH) $@; \
	fi


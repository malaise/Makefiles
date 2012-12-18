ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif

ADAWARN        ?= true
ifeq ($(ADAWARN),true)
ADAFLAG        := $(ADAFLAG) -gnatwa
endif

GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato -fstack-check -gnat05
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATSTUBPOST   := -cargs -gnat05
GNATHTMLOPT    ?= -d

GNATHTML       := $(GNATPATH)/gnathtml.pl $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe

ifdef HTML
HTML           = html
endif

ADA_FILTER     := 2>&1 | awk -v ADAOPT=$(ADAOPT) ' \
  BEGIN {code=0} \
  function strip(file,suff) {gsub(suff,"",file); return file} \
  ($$0 ~ /gnatmake: .+ up to date./) {next} \
  ($$2 == "warning:") {print; next} \
  ($$1 == "gcc" && $$2 == "-c" ) { \
    printf "ADA %s %s\n",ADAOPT,strip($$NF,"\\.\\./"); next \
  } \
  ($$1 == "gnatbind") {printf "BIND %s\n",strip($$NF,"\\.ali"); next} \
  ($$1 == "gnatlink") { \
    if ($$3 == "-shared-libgcc") {printf "LINK %s\n",strip($$2,"\\.ali")} \
    else {printf "LINK_STATIC %s\n",strip($$2,"\\.ali")} \
    next \
  } \
  {code=1; print} \
  END {exit (code)} \
'

include $(TEMPLATES)/units.mk
LIBS := $(filter-out $(SUBUNITS) $(NOTUNITS), $(UNITS))

BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .ads .adb .o .ali .stat
.PHONY : all libs echoadaview lsunits nohtml
.SECONDARY : $(DIRS) $(BEXES)

TOBUILD := dirs afpx libs exes git texi txt gpr

all : $(TOBUILD) $(HTML)

clean_all : clean clean_exe clean_afpx clean_html clean_texi clean_txt

nohtml : $(TOBUILD)

include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk

dirs : $(DIRS)


# Static and dynamic exe
$(BIN)/%.stat : $(DIRS) $(LIB)/%.o %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F:%.stat=%) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -static \
	  -largs $(LARGS_$(@F)) $(LARGS) -lm $(ADA_FILTER)

$(BIN)/% : $(DIRS) $(LIB)/%.o %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -shared \
	  -largs $(CPATHL) $(CLIBS_$(@F):%=-l%) $(CLIBS:%=-l%) \
                           $(LARGS_$(@F)) $(LARGS) $(ADA_FILTER)

# Compile local libraries
libs :
	 @cd $(LIB); \
	 res=0; \
	 for unit in $(LIBS); do \
	    if [ -f ../$$unit.adb ] ; then \
	      src=$$unit.adb; \
	    else \
	      src=$$unit.ads; \
	    fi; \
	    $(ADA) ../$$src $(GARGS) -cargs $(CARGS) $(ADA_FILTER); \
	    if [ $$? -ne 0 ] ; then \
	      res=1; \
	    fi; \
	  done; \
	  exit $$res

exes :
	@if [ ! -z "$(EXES)" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(BEXES); \
	  for file in $(EXES) ; do \
	    $(LN) -f $(BIN)/$$file .; \
	  done; \
	fi

lsunits :
	@for file in *.ads ; do \
	  echo `basename $$file .ads`; \
	done; \
	for file in *.adb; do \
	  if [ ! -f `basename $$file .adb`.ads ] ; then \
	    echo `basename $$file .adb`; \
	  fi; \
	done

# Make a stub of body from spec
%.adb : %.ads
	@if [ ! -f $@ ] ; then \
	  type astub > /dev/null 2>&1; \
	  if [ $$? -eq 0 ] ; then \
	    astub $<; \
	  else \
	    $(ECHO) "ERROR: astub not found."; \
	    exit 1; \
	  fi; \
	fi

echoadaview :
	@$(ECHO) $(ADAVIEW)


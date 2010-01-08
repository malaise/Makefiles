ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif
ifeq ($(ADAWARN),true)
ADAFLAG        := $(ADAFLAG) -gnatwa
endif

GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato -fstack-check
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATHTMLOPT    ?= -d

GNATHTML       := $(GNATPATH)/gnathtml.pl $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe
OF             ?= $(LIBS) $(EXES)
LSDEPARGS      := -v $(OF)

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
BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .ads .adb .o .ali .stat
.PHONY : all alis libs afpx lsdep echoadaview
.SECONDARY : $(BEXES)

$(LIB)/%.ali $(LIB)/%.o :: %.adb
	@cd $(LIB); \
	@$(ADA) ../$(<F) $(GARGS) -cargs $(CARGS) $(ADA_FILTER)

all : $(DIRS) alis libs $(EXES) afpx

include $(TEMPLATES)/post.mk

# Static and dynamic exe
$(BIN)/%.stat : $(DIRS) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F:%.stat=%) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -static \
	  -largs $(LARGS_$(@F)) $(LARGS) -lm $(ADA_FILTER)

$(BIN)/% : $(DIRS) %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -shared \
	  -largs $(CPATHL) $(CLIBS_$(@F):%=-l%) $(CLIBS:%=-l%) \
                           $(LARGS_$(@F)) $(LARGS) $(ADA_FILTER)

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
  res=0; \
  for file in $(LIBS); do \
    if [ -f ../$$file.adb ] ; then \
      src=$$file.adb; \
    else \
      src=$$file.ads; \
    fi; \
    $(ADA) ../$$src $(GARGS) -cargs $(CARGS) $(ADA_FILTER); \
    if [ $$? -ne 0 ] ; then \
      res=1; \
    fi; \
  done; \
  exit $$res
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
	  echo "Error: alsdep not found."; \
	else \
	  export ADAVIEW="$(ADAVIEW)"; \
	  alsdep $(LSDEPARGS); \
	fi

echoadaview :
	@echo $(ADAVIEW)


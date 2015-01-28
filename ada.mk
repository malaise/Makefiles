ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif

ADAWARN        ?= true
ifeq ($(ADAWARN),true)
ADAFLAG        := $(ADAFLAG) -gnatwa -gnatw.k -gnatwl -gnatwo -gnatw.s -gnatwt -gnatw.u -gnatw.w
endif

GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato -fstack-check -gnat2012
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATSTUBPOST   := -cargs -gnat2012
GNATHTMLOPT    ?= -d

GNATHTML       := $(GNATPATH)/gnathtml.pl $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe
LARGS          := $(LARGS) -L/usr/local/lib

ifdef HTML
HTML           = html
endif

ADA_FILTER     := 2>&1 | awk -v ADAOPT=$(ADAOPT) -v OPTIM=$$optim ' \
  BEGIN {code=0} \
  function strip(file,suff) {gsub(suff,"",file); return file} \
  ($$0 ~ /gnatmake: .+ up to date./) {next} \
  ($$2 == "warning:") {print; next} \
  ($$1 == "gcc" && $$2 == "-c" ) { \
    printf "ADA %s %s %s \n",ADAOPT,OPTIM,strip($$NF,"\\.\\./"); next \
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
ifdef NOFILTER
ADA_FILTER =
endif

PREPROCESSOR = awk -v DEFINES=" $(PARGS) $(PARGS_$<) " ' \
  BEGIN {LVL=0; KEEP[LVL]=1} \
    ($$0 ~ /^[[:blank:]]*--\#IfDef[[:blank:]]+[^[:blank:]]+[[:blank:]]*$$/) { \
      LVL++; KEEP[LVL]=(KEEP[LVL-1] && match (DEFINES, " " $$2 " ")); OK[LVL]=KEEP[LVL]; LINE[LVL]=NR; next} \
    ($$0 ~ /^[[:blank:]]*--\#ElsifDef[[:blank:]]+[^[:blank:]]+[[:blank:]]*$$/) { \
      KEEP[LVL]=(!OK[LVL] && KEEP[LVL-1] && match (DEFINES, " " $$2 " ")); OK[LVL]=OK[LVL]||KEEP[LVL]; next} \
    ($$0 ~ /^[[:blank:]]*--\#ElseDef[[:blank:]]*$$/) {KEEP[LVL]=(KEEP[LVL-1] && (!KEEP[LVL])); next} \
    ($$0 ~ /^[[:blank:]]*--\#EndifDef[[:blank:]]*$$/) {LVL--; next} \
    (KEEP[LVL]) {print; next } \
    END {if (LVL != 0) {print "APP ERROR: Unterminated condition started at line " LINE[LVL] > "/dev/stderr"; exit (1)}} \
'

include $(TEMPLATES)/units.mk
LIBS := $(filter-out $(SUBUNITS) $(NOTUNITS), $(UNITS))
PREPROC := $(wildcard *.aps *.apb)

BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .ads .adb .aps .apb .o .ali .stat
.PHONY : all preprocess libs echoadaview lsunits nohtml
.SECONDARY : $(DIRS) $(BEXES)

TOBUILD := dirs afpx preprocess libs exes git texi txt gpr

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
	  -largs $(CPATHL) $(LARGS_$(@F)) $(LARGS) \
           $(CLIBS_$(@F):%=-l%) $(CLIBS:%=-l%) -lm $(ADA_FILTER)

# Compile local libraries
libs :
	 @cd $(LIB); export OPTIMIZED=" $(OPTIMIZED) "; \
	 res=0; \
	 for unit in $(LIBS); do \
	    if [ -f ../$$unit.adb ] ; then \
	      src=$$unit.adb; \
	    else \
	      src=$$unit.ads; \
	    fi; \
	    $(ECHO) "$$OPTIMIZED" | grep " $$unit " >/dev/null; \
	    if [ $$? -eq 0 ] ; then \
	      export optim="-O2"; \
	    else \
	      export optim=""; \
	    fi; \
	    $(ADA) ../$$src $(GARGS) $$optim -cargs $(CARGS) $(ADA_FILTER); \
	    if [ $$? -ne 0 ] ; then \
	      res=1; \
	    fi; \
	  done; \
	  exit $$res

exes :
	@res=0; \
	if [ ! -z "$(EXES)" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(BEXES); \
	  if [ $$? -ne 0 ] ; then \
	    res=1; \
	  fi; \
	  for file in $(EXES) ; do \
	    $(LN) -f $(BIN)/$$file .; \
	  done; \
	fi; \
	exit $$res

preprocess :
ifdef PREPROC
	@for file in $(PREPROC) ; do \
	  if [ `basename $$file .aps`.aps = $$file ] ; then \
	    name=`basename $$file .aps`; \
	    suff=ads; \
	  else \
	    name=`basename $$file .apb`; \
            suff=adb; \
	  fi; \
	  $(MAKE) $(NOPRTDIR) $(SILENT) $$name.$$suff; \
	done
endif

%.ads : %.aps
	@$(ECHO) APP $(PARGS) $(PARGS_$<) $<
	@$(PREPROCESSOR) < $< > $@	

%.adb : %.apb
	@$(ECHO) APP $(PARGS_$<) $<
	$(PREPROCESSOR) < $< > $@	

lsunits : preprocess
	@for file in *.ads ; do \
	  $(ECHO) `basename $$file .ads`; \
	done; \
	for file in *.adb; do \
	  if [ ! -f `basename $$file .adb`.ads ] ; then \
	    $(ECHO) `basename $$file .adb`; \
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


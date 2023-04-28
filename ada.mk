ifdef ADAVIEW
GNATMAKEFLAG   := $(patsubst %,-aI%,$(ADAVIEW)) $(patsubst %,-aO%/$(LIB),$(ADAVIEW))
GNATHTMLFLAG   := $(patsubst %,-I%,$(ADAVIEW))
GNATSTUBFLAG   := $(patsubst %,-I%,$(ADAVIEW))
endif

ADAWARN        ?= true
ifeq ($(ADAWARN),true)
ADAFLAG        := $(ADAFLAG) -gnatwa -gnatwb -gnatwc -gnatw.c -gnatwf -gnatwg -gnatw.i -gnatwj -gnatwk -gnatwm -gnatw.n -gnatwp -gnatw.p -gnatwr -gnatwu -gnatw.x\
			     -gnatyO -Wunused -Wuninitialized 
endif

GNATMAKEFLAG   := $(GNATMAKEFLAG) -gnato -fstack-check -gnat2012
GNATHTMLFLAG   := -I$(LIB) $(GNATHTMLFLAG)
GNATSTUBFLAG   := $(GNATSTUBFLAG) -gnaty2 -q
GNATSTUBPOST   := -cargs -gnat2012
GNATHTMLOPT    ?= -d

GNATHTML       := $(wildcard $(GNATPATH)/gnathtml) $(wildcard $(GNATPATH)/gnathtml.pl)  $(GNATHTMLFLAG)
GNATMAKE       := $(GNATPATH)/gnatmake $(GNATMAKEFLAG) $(ADAOPT) $(ADAFLAG)
GNATSTUB       := $(GNATPATH)/gnatstub $(GNATSTUBFLAG)
GNATMETRIC     := $(GNATPATH)/gnatmetric -q -sfn --construct-nesting
NESTMAX        ?= 5
ADA            := $(GNATMAKE) -c

CARGS          := $(CARGS) -pipe
LARGS          := $(LARGS) -L/usr/local/lib -L/lib/$(ARCH)

ifdef HTML
HTML           := html
endif

ADA_FILTER     := 2>&1 | awk -v ADAOPT=$(ADAOPT) -v OPTIM=$$optim ' \
  BEGIN {code=0} \
  function strip(file,suff) {gsub(suff,"",file); return file} \
  ($$0 ~ /gnatmake: .+ up to date.$$/) {next} \
  ($$2 == "warning:") { \
     if ($$5 != "GNU_PROPERTY_TYPE") {print} \
     next; \
   } \
  ($$2 == "info:") {next} \
  ($$1 ~ /(.*gnu-)?gcc(-.+)?$$/ && $$2 == "-c" ) { \
    printf "ADA %s %s %s \n",ADAOPT,OPTIM,strip($$NF,"\\.\\./"); next \
  } \
  ($$1 ~ /(.*gnu-)?gnatbind(-.+)?$$/) {printf "BIND %s\n",strip($$NF,"\\.ali"); next} \
  ($$1 ~ /(.*gnu-)?gnatlink(-.+)?$$/) { \
    for (i = 1; i <= NF; i++) { \
      if ($$i == "-o") { \
        TARGET=$$(i+1); \
        break; \
      }; \
    }; \
    I = match(TARGET, ".stat"); \
    if (I != (length(TARGET)-length(".stat")+1)) {I = 0}; \
    if (I == 0) {printf "LINK %s\n",strip($$2,"\\.ali")} \
    else {printf "LINK_STATIC %s\n",strip($$2,"\\.ali")} \
    next \
  } \
  {code=1; print} \
  END {exit (code)} \
'
ifdef NOFILTER
ADA_FILTER :=
endif


include $(TEMPLATES)/units.mk
UNITS := $(filter-out $(SUBUNITS) $(NOTUNITS), $(ALLUNITS))
LIBS := $(subst .,-,$(UNITS))

PREPROCESSOR = app '--prefix=--\#@' $(PARGS) $(PARGS_$<)
PREPROC := $(wildcard *.aps *.apb)
APP := $(wildcard app.adb)
ifdef PREPROC
ifdef APP
PREREQS := $(PREREQS) app
endif
endif

SPREREQS := $(PREREQS:%=../%.adb)

ADASRC = TRUE

.SUFFIXES : .ads .adb .aps .apb .o .ali .stat
.PHONY : all preprocess prerequisit libs echoadaview lsunits lssubunits lsallunits nohtml metrics
.SECONDARY : $(DIRS)

TOBUILD := dirs prerequisit preprocess afpx libs exes git texi txt gpr

all : $(TOBUILD) $(HTML)

clean_all : clean clean_exe clean_afpx clean_html clean_texi clean_txt clean_adactl

nohtml : $(TOBUILD)

include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk

dirs : $(DIRS)

# Make (compile and link) prerequisits
prerequisit :
	@res=0; \
	if [ ! -z "$(PREREQS)" ]; then \
	  cd $(LIB); \
	  $(ADA) $(SPREREQS) $(GARGS) -cargs $(CARGS) $(ADA_FILTER); \
	  cd ..; \
	  $(MAKE) $(NOPRTDIR) -s $(PREREQS); \
	  if [ $$? -ne 0 ] ; then \
	    res=1; \
	  fi; \
	fi; \
	exit $$res

# Static and dynamic exe
%.stat : $(DIRS) $(LIB)/%.o %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F:%.stat=%) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
	  -bargs -static \
	  -largs $(LARGS_$(@F)) $(LARGS) -lm $(ADA_FILTER)

% : $(DIRS) $(LIB)/%.o %.adb
	@cd $(LIB); \
	$(GNATMAKE) ../$(@F) -o ../$@ \
	  $(GARGS_$(@F)) $(GARGS) \
	  -cargs $(CARGS_$(@F)) $(CARGS) \
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
	  $(MAKE) $(NOPRTDIR) -s $(EXES); \
	  if [ $$? -ne 0 ] ; then \
	    res=1; \
	  fi; \
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
	@$(ECHO) APP $(PARGS) $(PARGS_$<) $<
	$(PREPROCESSOR) < $< > $@	

lsunits : 
	@echo $(UNITS)

lssubunits :
	@echo $(SUBUNITS)

lsallunits : 
	@echo $(ALLUNITS)

lsexes : 
	@echo $(EXES)


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

metrics :
	@rm -f *.adb.metrix
	@$(GNATMETRIC) *.adb -cargs $(ADAVIEW:%=-I %)
	@awk -v MAX=$(NESTMAX) ' \
          (FNR == 1) {NAME=""} \
          ($$1 == "Metrics" && $$2 == "computed" && $$3 == "for") { \
            FILE=$$4; \
            FILEPUT=0; \
            next; \
          } \
          (NF >= 7 && $$2 != "(package" && $$(NF-3) == "at" \
           && $$(NF-2) == "lines") { \
            NAME=$$1 " (" $$(NF-1)$$(NF); \
            next; \
          } \
          ($$1 == "maximal" && $$2 == "construct" \
           && $$3 =="nesting:" && NAME != "" && $$4 > MAX) { \
            if (FILEPUT == 0) { \
              printf FILE "\n"; \
              FILEPUT=1; \
            } \
            printf "  " NAME " " $$4 "\n"; \
            NAME=""; \
            next; \
          } \
        ' *.adb.metrix
	@rm -f *.adb.metrix


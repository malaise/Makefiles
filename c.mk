# If DEBUG is set, define it to '-g -DDEBUG'
ifneq ($(origin DEBUG), undefined)
  CDEBUG := -g -DDEBUG
endif

CC_Linux        := gcc
CPP_Linux       := g++
CCOPT_Linux     ?= -pedantic -Wall -W -Wpointer-arith \
	-Wbad-function-cast -Wcast-qual -Wcast-align -Wwrite-strings \
	-Wsign-compare -Wstrict-prototypes -Wmissing-prototypes  \
	-Wmissing-declarations -Wmissing-noreturn -Wunreachable-code -Winline \
	-Wfloat-equal -Wundef
CCOPT_Linux     += -Werror
CPPOPT_Linux    ?= -pedantic -Wall -W -Wpointer-arith \
	-Wcast-qual -Wcast-align -Wwrite-strings -Wsign-compare \
	-Wmissing-noreturn -Wunreachable-code -Winline -Wfloat-equal -Wundef
CPPOPT_Linux    += -Werror


LD              := ld

CFLAGS_Linux    := -pipe -fPIC -std=gnu99 -D_FILE_OFFSET_BITS=64

SOOPT_Linux     := 
CDEP            := cdep.mk

CC              := $(CC_$(HOST))
CPP             := $(CPP_$(HOST))
CFLAGS          := $(CFLAGS) $(CFLAGS_$(HOST)) $(CDEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT) $(CCOPT_$(HOST))
CPPOPT          := $(CPPOPT) $(CPPOPT_$(HOST))
SOOPT           := $(SOOPT) $(SOOPT_$(HOST))
LDFLAGS         := $(LDFLAGS) -L/usr/local/lib

DINCLD := $(DINCL:%=-I../%) $(DLIBA:%=-I../%)
DLIBAD := $(foreach dir,$(DLIBA),../$(dir)/$(LIB)/lib$(dir).a)

OEXES  := $(EXES:%=$(LIB)/%.o)
ALIBS  := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%=$(LIB)/%.so)

SRCS := $(wildcard *.c) $(wildcard *.cpp) 
OBJS := $(patsubst %.c,$(LIB)/%.o,$(wildcard *.c)) \
        $(patsubst %.cpp,$(LIB)/%.o,$(wildcard *.cpp))



.SUFFIXES : .h .c .hpp .cpp .o .a .so .mk
.PHONY : all install dep clean_dep clean_installed one_cdep
.SECONDARY : $(BEXES) $(OEXES) $(ALIBS) $(SOLIBS) $(OBJS)

ifdef LINKFROM
LINKS := $(FILES2LINK)
FILES4LINK := $(FILES2LINK:%=$(LINKFROM)/%)
endif

all : txt $(DIRS) $(LINKS) dep $(ALIBS) $(SOLIBS) $(EXES) git texi
	$(POST_LIBS)
	$(POST_EXES)
	@$(MAKE) $(NOPRTDIR) -s install

clean_all : clean clean_exe clean_texi clean_txt clean_dep

ifdef LINKFROM
$(LINKS) :
	@$(ECHO) "LN $(FILES4LINK) ."
	@$(LN) $(FILES4LINK) .
else
$(LINKS) :
endif


$(LIB)/%.o : %.c
	@$(ECHO) "CC $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@"
	@$(CC) $(CCOPT) $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@

$(LIB)/%.o : %.cpp
	@$(ECHO) "CPP $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.cpp) -o $@"
	@$(CPP) $(CPPOPT) $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.cpp) -o $@

$(LIB)/%.so : $(OBJS)
	@if [ "$(OBJS_$(@F:%.so=%))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))); \
	fi
	@$(ECHO) LD -shared $(SOOPT) -o $@ $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))) -lc
	@$(LD) -shared $(SOOPT) -o $@ $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))) -lc
	@-$(RM) so_locations

$(LIB)/%.a : $(OBJS)
	@if [ "$(OBJS_$(@F:%.a=%))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.a=%))); \
	fi
	@$(ECHO) AR crs $@ $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))
	@$(AR) crs $@ $(patsubst %,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))

% : %.c

% : %.cpp

% : $(LIB)/%.o $(SOLIBS) $(DLIBAD)
	@if [ "$(LIBS_$(@F))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(patsubst %,$(LIB)/%.a,$(LIBS_$(@F))); \
	fi
	@if [ -f "$(@F).c" ] ; then \
	  ECOM=CC; \
	  COM=$(CC); \
	else \
	  ECOM=CPP; \
	  COM=$(CPP); \
	fi; \
	$(ECHO) $$ECOM -o $@ $< $(LDFLAGS) $(LIBS_$(@F):%=$(LIB)/%.a) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm; \
	$$COM -o $@ $< $(LDFLAGS) $(LIBS_$(@F):%=$(LIB)/%.a) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm

INSTALLED_HEADS := $(strip $(INST_HEADS:%=$(DEST_HEADS)/%))
INSTALLED_LIBS := $(strip $(INST_LIBS:%=$(DEST_LIBS)/%.a) $(INST_LIBS:%=$(DEST_LIBS)/%.so))
INSTALLED_EXES := $(strip $(INST_EXES:%=$(DEST_EXES)/%))
INSTALLED := $(strip $(INSTALLED_HEADS) $(INSTALLED_LIBS) $(INSTALLED_EXES))

$(DEST_HEADS)/% : %
	$(CP) $< $@
	$(CHMOD_AR) $@

$(DEST_LIBS)/%.so : $(LIB)/%.so
	$(CP) $< $@
	$(CHMOD_ARX) $@

$(DEST_LIBS)/%.a : $(LIB)/%.a
	$(CP) $< $@
	$(CHMOD_AR) $@

$(DEST_EXES)/% : %
	$(CP) $< $@
	$(CHMOD_ARX) $@

install : $(INSTALLED)

# Add local dependencies of *.o on .c[pp] and .h[pp] in $(CDEP)
# Call make to ré-evaluate wildcard (after LN)
#  and to evaluate CARGS_<file>
dep : 
	@$(MAKE) $(SILENT) $(NOPRTDIR) $(CDEP)


one_cdep :
	@$(CC) $(DINCLD) $(CARGS_$(CARGS_NAME)) -MM $(CARGS_FILE) 2>&1 \
	  | awk -v LIB=$(LIB) ' \
	    ($$2 == "error:") {print >"/dev/stderr"; exit 1} \
	    ($$1 ~ /.*\.o/) {print LIB"/"$$0; next} \
	    {print}' >> $(CDEP)

$(CDEP) : $(wildcard *.c *.cpp *.h *.hpp)
	@echo CDEP
	@echo -n "" > $(CDEP); \
	for FILE in $(SRCS); do \
	  export CARGS_FILE=$$FILE; \
	  export CARGS_NAME=`basename $$FILE .c`; \
	  export CARGS_NAME=`basename $$CARGS_NAME .cpp`; \
	 $(MAKE) $(NOPRTDIR) one_cdep; \
	done; \
	if [ $$? -ne 0 ] ; then \
	  rm -f $(CDEP); \
	  exit 1; \
	fi

clean_dep : clean_git
	@$(RM) $(CDEP)

clean_installed :
	@$(RM) $(INSTALLED)

include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk


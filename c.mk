# If DEBUG is set, define it to '-g -DDEBUG'
ifneq ($(origin DEBUG), undefined)
  CDEBUG = -g -DDEBUG
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

DINCLD := $(DINCL:%=-I../%) $(DLIBA:%=-I../%)
DLIBAD := $(foreach dir,$(DLIBA),../$(dir)/$(LIB)/lib$(dir).a)

OEXES  := $(EXES:%=$(LIB)/%.o)
BEXES  := $(EXES:%=$(BIN)/%)
ALIBS  := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%=$(LIB)/%.so)

OBJS := $(patsubst %.c,$(LIB)/%.o,$(wildcard *.c))


.SUFFIXES : .h .c .hpp .cpp .o .a .so
.PHONY : all install dep clean_dep
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

$(BIN)/% : $(LIB)/%.o $(SOLIBS)
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
	$(ECHO) $$ECOM -o $@ $< $(LIBS_$(@F):%=$(LIB)/%.a) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm; \
	$$COM -o $@ $< $(LIBS_$(@F):%=$(LIB)/%.a) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm

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

$(DEST_EXES)/% : $(BIN)/%
	$(CP) $< $@
	$(CHMOD_ARX) $@

install : $(INSTALLED)

# Add local dependancies of *.o on .c[pp] and .h[pp] in $(CDEP)
dep dep : $(CDEP)

$(CDEP) : $(wildcard *.c *.cpp *.h *.hpp)
	@$(CC) $(DINCLD) -MM `ls *.c *.cpp 2> /dev/null` 2>/dev/null | awk -v LIB=$(LIB) ' \
	  ($$1 ~ /.*\.o/) {print LIB"/"$$0; next} \
          {print}' > $(CDEP)

clean_dep :
	@$(RM) $(CDEP)

include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk


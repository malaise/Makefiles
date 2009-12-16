# If DEBUG is set, define it to '-g -DDEBUG'
ifneq ($(origin DEBUG), undefined)
  CDEBUG = -g -DDEBUG
endif

CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos

SOOPT_OSF1      := -all

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

CFLAGS_Linux    := -pipe

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

.SUFFIXES : .h .c .hpp .cpp .o .a .so
.PHONY : all install cdep dep clean_cdep clean_dep
.SECONDARY : $(BEXES) $(OEXES) $(ALIBS) $(SOLIBS)

ifdef LINKFROM
LINKS := $(FILES2LINK)
FILES4LINK := $(FILES2LINK:%=$(LINKFROM)/%)
endif

all : $(DIRS) $(LINKS) $(ALIBS) $(SOLIBS)
	$(POST_LIBS)
	@if [ "$(INSTALLED_HEADS)" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(INSTALLED_HEADS); \
	fi
	@if [ "$(INSTALLED_LIBS)" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(INSTALLED_LIBS); \
	fi
	@if [ "$(EXES)" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(EXES); \
	fi
	$(POST_EXES)
	@if [ "$(INSTALLED_EXES)" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(INSTALLED_EXES); \
	fi

ifdef LINKFROM
$(LINKS) :
	$(LN) $(FILES4LINK) .
else
$(LINKS) :
endif

$(LIB)/%.o : %.c
	@echo "CC $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@"
	@$(CC) $(CCOPT) $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@

$(LIB)/%.o : %.cpp
	@echo "CPP $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.cpp) -o $@"
	@$(CC) $(CPPOPT) $(CFLAGS) $(DINCLD) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.cpp) -o $@

$(LIB)/%.so :
	@if [ "$(OBJS_$(@F:%.so=%))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))); \
	fi
	$(LD) -shared $(SOOPT) -o $@ $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))) -lc
	-$(RM) so_locations

$(LIB)/%.a :
	@if [ "$(OBJS_$(@F:%.a=%))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) -s $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%))); \
	fi
	$(AR) crs $@ $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))

$(BIN)/% : $(LIB)/%.o
	@if [ "$(LIBS_$(@F))" != "" ]; then \
	  $(MAKE) $(NOPRTDIR) $(patsubst %,$(LIB)/%,$(LIBS_$(@F))); \
	fi
	@if [ -f "$(@F).c" ] ; then \
	  $(CC) -o $@ $< $(LIBS_$(@F):%=$(LIB)/%) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm; \
	else \
	  $(CPP) -o $@ $< $(LIBS_$(@F):%=$(LIB)/%) $(DLIBAD) $(LARGS_$(@F)) -lpthread -lm; \
	fi

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

# Extract #include "<file>.h" directives of all .c, .cpp, .h and .hpp
# Add local dependancies in $(CDEP)
cdep dep :
	@$(RM) $(CDEP)
	@$(TOUCH) $(CDEP)
	@hlist="`ls *.h 2> /dev/null`"; \
	if [ -z "$$hlist" ] ; then \
	  exit 0; \
	fi; \
	for file in `ls *.c *.cpp *.h *.hpp` ; do \
	  list=`awk -v LIST="$$hlist" ' \
	    BEGIN { \
	      NLIST=split(LIST, HLIST, " ") \
	    } \
	    ( ($$1 == "#include") && ($$2 ~ "\".+\\\.h\"") ) { \
	      INCL = substr ($$2, 2, length($$2)-2); \
	      for (I = 1; I <= NLIST; I++) { \
	        if (INCL == HLIST[I]) { \
	          printf " " INCL; \
	          next \
	        } \
	      } \
	    }' $$file` ; \
	  if [ ! -z "$$list" ] ; then \
	    echo "$$file :$$list" >> $(CDEP); \
	  fi \
	done \

clean_cdep clean_dep :
	@$(RM) $(CDEP)

include $(TEMPLATES)/post.mk


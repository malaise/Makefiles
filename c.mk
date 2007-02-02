CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos

SOOPT_OSF1      := -all

CC_Linux        := gcc
CCOPT_Linux     ?= -pedantic -Wall -W -Wpointer-arith \
	-Wbad-function-cast -Wcast-qual -Wcast-align -Wwrite-strings \
	-Wsign-compare -Wstrict-prototypes -Wmissing-prototypes  \
	-Wmissing-declarations -Wmissing-noreturn -Wunreachable-code -Winline \
	-Wfloat-equal -Wundef
CCOPT_Linux     += -Werror

LD              := ld

CFLAGS_Linux    := -pipe

SOOPT_Linux     := 
CDEP            := cdep.mk

CC              := $(CC_$(HOST))
CFLAGS          := $(CFLAGS) $(CFLAGS_$(HOST)) $(DEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT) $(CCOPT_$(HOST))
SOOPT           := $(SOOPT) $(SOOPT_$(HOST))

OEXES  := $(EXES:%=$(LIB)/%.o)
BEXES  := $(EXES:%=$(BIN)/%)
ALIBS  := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%=$(LIB)/%.so)

.SUFFIXES : .h .c .o .a .so
.PHONY : all install cdep dep clean_cdep clean_dep
.SECONDARY : $(BEXES) $(OEXES) $(ALIBS) $(SOLIBS)

all : $(DIRS) $(LINKS) $(ALIBS) $(SOLIBS) $(INSTALLED_HEADS)
	$(POST_LIBS)
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
LINKS := $(FILES2LINK)
FILES4LINK := $(FILES2LINK:%=$(LINKFROM)/%)

$(LINKS) :
	$(LN) $(FILES4LINK) .
else
$(LINKS) :

endif

$(LIB)/%.o : %.c
	@echo "CC $(CFLAGS) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@"
	@$(CC) $(CCOPT) $(CFLAGS) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@

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
	$(CC) -o $@ $< $(LIBS_$(@F):%=$(LIB)/%) -L$(LIB) $(LARGS_$(@F))

INSTALLED_HEADS := $(strip $(INST_HEADS:%=$(DEST_HEADS)/%))
INSTALLED_LIBS := $(strip $(INST_LIBS:%=$(DEST_LIBS)/%.a) $(INST_LIBS:%=$(DEST_LIBS)/%.so))
INSTALLED_EXES := $(strip $(INST_EXES:%=$(DEST_EXES)/%))
INSTALLED := $(strip $(INSTALLED_HEADS) $(INSTALLED_LIBS) $(INSTALLED_EXES))

$(DEST_HEADS)/% : %
	/bin/cp -f $< $@
	/bin/chmod a+r $@

$(DEST_LIBS)/% : $(LIB)/%
	/bin/cp -f $< $@
	/bin/chmod a+r $@

$(DEST_EXES)/% : $(BIN)/%
	/bin/cp -f $< $@
	/bin/chmod a+r $@

install : $(INSTALLED)

# Extract #include "<file>.h" directives of all .c and .h
# Add local dependancies in $(CDEP)
cdep dep :
	@$(RM) $(CDEP)
	@$(TOUCH) $(CDEP)
	@hlist="`ls *.h 2> /dev/null`"; \
	if [ -z "$$hlist" ] ; then \
	  exit 0; \
	fi; \
	for file in `ls *.[ch]` ; do \
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


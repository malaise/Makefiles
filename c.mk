CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos

SOOPT_OSF1      := -all

CC_Linux        := gcc
CCOPT_Linux     := -Wall -Wpointer-arith -Wcast-qual \
		-Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes

LD              := ld

CFLAGS_Linux    := -pipe

SOOPT_Linux     := 

CC              := $(CC_$(HOST))
DEBUG           := 
CFLAGS          := $(CFLAGS) $(CFLAGS_$(HOST)) $(DEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT) $(CCOPT_$(HOST))
SOOPT           := $(SOOPT) $(SOOPT_$(HOST))

OEXES  := $(EXES:%=$(LIB)/%.o)
BEXES  := $(EXES:%=$(BIN)/%)
ALIBS  := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%=$(LIB)/%.so)

.SUFFIXES : .h .c .o .a .so
.PHONY : all install
.SECONDARY : $(BEXES) $(OEXES)

$(LIB)/%.o : %.c
	$(CC) $(CCOPT) $(CFLAGS) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@

$(LIB)/%.so :
	@if [ "$(OBJS_$(@F:%.so=%))" != "" ]; then \
	  make $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))); \
	fi
	$(LD) -shared $(SOOPT) -o $@ $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))) -lc
	-$(RM) so_locations

$(LIB)/%.a :
	@if [ "$(OBJS_$(@F:%.a=%))" != "" ]; then \
	  make $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%))); \
	fi
	$(AR) crvs $@ $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))

$(BIN)/% : $(LIB)/%.o
	@if [ "$(LIBS_$(@F))" != "" ]; then \
	  make $(patsubst %,$(LIB)/%,$(LIBS_$(@F))); \
	fi
	$(CC) -o $@ $< $(LIBS_$(@F):%=$(LIB)/%) $(LARGS_$(@F))

INSTALLED_HEADS := $(INST_HEADS:%=$(DEST_HEADS)/%)
INSTALLED_LIBS := $(INST_LIBS:%=$(DEST_LIBS)/%.a) $(INST_LIBS:%=$(DEST_LIBS)/%.so)
INSTALLED_EXES := $(INST_EXES:%=$(DEST_EXES)/%)
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

all : $(DIRS) $(ALIBS) $(SOLIBS) $(EXES)
	$(DO_POST)
	@if [ "$(INSTALLED)" != "" ]; then \
	  make install; \
	fi

install : $(INSTALLED)

include $(TEMPLATES)/post.mk


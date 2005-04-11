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
CFLAGS          := $(CFLAGS_$(HOST)) $(DEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT_$(HOST))
SOOPT           := $(SOOPT_$(HOST))

OEXES := $(EXES:%=$(LIB)/%.o)
BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .h .c .o .a .so
.PHONY : all install
.SECONDARY : $(BEXES) $(OEXES)

ALIBS  := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%=$(LIB)/%.so)

$(LIB)/%.o : %.c
	$(CC) $(CCOPT) $(CFLAGS) $(CARGS_$(@F:%.o=%)) -c $(@F:%.o=%.c) -o $@

$(LIB)/%.so :
	$(LD) -shared $(SOOPT) -o $@\
	  $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.so=%))) -lc
	-$(RM) so_locations

$(LIB)/%.a :
	@make $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))
	$(AR) crvs $@ $(patsubst %.o,$(LIB)/%.o,$(OBJS_$(@F:%.a=%)))

$(BIN)/% : $(LIB)/%.o
	$(CC) -o $@ $< $(LIBS_$(@F):%=$(LIB)/%) $(LARGS_$(@F))

INSTALLED_HEADS := $(INST_HEADS:%=$(DEST_HEADS)/%)
INSTALLED_LIBS := $(INST_LIBS:%=$(DEST_LIBS)/%.a) $(INST_LIBS:%=$(DEST_LIBS)/%.so)
INSTALLED_EXES := $(INST_EXES:%=$(DEST_EXES)/%)

$(DEST_HEADS)/% : %
	/bin/cp -f $< $@
	/bin/chmod a+r $@

$(DEST_LIBS)/% : $(LIB)/%
	/bin/cp -f $< $@
	/bin/chmod a+r $@

$(DEST_EXES)/% : $(BIN)/%
	/bin/cp -f $< $@
	/bin/chmod a+r $@

all : $(DIRS) $(ALIBS) $(SOLIBS) $(INSTALLED_HEADS) $(INSTALLED_LIBS) $(EXES) $(INSTALLED_EXES)
	$(DO_POST)

include $(TEMPLATES)/post.mk


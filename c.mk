CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos
SOOPT_OSF1      := -all

CC_Linux        := gcc
CCOPT_Linux     := -Wall
SOOPT_Linux     := 

CC              := $(CC_$(HOST))
DEBUG           := 
CFLAGS          := $(CFLAGS_$(HOST)) $(DEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT_$(HOST))
SOOPT           := $(SOOPT_$(HOST))

BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .h .c .o .a .so
.PHONY : all
.SECONDARY : $(BEXES)

LIBS   := $(LIBS:%=$(LIB)/lib%.a)
SOLIBS := $(LIBS:%.a=%.so)
OBJS   := $(OBJS:%=$(LIB)/%)

$(LIB)/%.o : %.c
	$(CC) $(CCOPT) $(CFLAGS) -c $< -o $@

ifdef DEST
$(DEST)/% : $(LIB)/%
	cp $< $@
	chmod a+r $@
endif

all : $(DIRS) $(LIBS) $(SOLIBS) $(EXES)

install : $(INSTALLED)

include $(TEMPLATES)/post.mk


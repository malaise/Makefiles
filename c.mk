CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos
SOOPT_OSF1      := -all

CC_Linux        := gcc
CCOPT_Linux     := -Wall
SOOPT_Linux     := 

CC              := $(CC_$(HOST))
DEBUG           := 
CFLAGS          := $(CFLAGS_$(HOST)) $(DEBUG) -pthread
CCOPT           := $(CCOPT_$(HOST))
SOOPT           := $(SOOPT_$(HOST))

.SUFFIXES: .h .c .o .a .so
.PHONY: all

LIBS   := $(LIBS:%=$(LIB)/lib%.a)
SOLIBS := $(LIBS:%.a=%.so)
OBJS   := $(OBJS:%=$(LIB)/%)

$(LIB)/%.o : %.c
	$(CC) $(CCOPT) $(CFLAGS) -c $< -o $@

$(DEST)/% : $(LIB)/%
	cp $< $@
	chmod a+r $@

all : $(DIRS) $(LIBS) $(SOLIBS) $(EXES) $(INSTALLED)

html :

include $(TEMPLATES)/post.mk


CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos

CC_Linux        := gcc
CCOPT_Linux     := -Wall

CC              := $(CC_$(HOST))
DEBUG           := 
#DEBUG           := -g -DDEBUG
CFLAGS          := $(CFLAGS_$(HOST)) $(DEBUG) -pthread
CCOPT           := $(CCOPT_$(HOST))

.SUFFIXES: .h .c .o .a .so
.PHONY: all

$(LIB)/%.o : %.c $(LIB)
	$(CC) $(CCOPT) $(CFLAGS) -c $< -o $@

%.so : %.a
	ld -shared -all -o $@ $< -lc
	\rm so_locations

LIBS := $(LIBS:%=$(LIB)/%.a)
SOLIBS := $(LIBS:%.a=%.so)

OBJS := $(OBJS:%=$(LIB)/%)

all : $(DIRS) $(LIBS) $(SOLIBS) $(EXES)

html :

include $(TEMPLATES)/post.mk


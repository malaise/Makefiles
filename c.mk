CC_OSF1         := cc
CCOPT_OSF1      := -O -std1 -warnprotos

SOOPT_OSF1      := -all

CC_Linux        := gcc
CCOPT_Linux     := -Wall -Wpointer-arith -Wcast-qual \
		-Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes

SOOPT_Linux     := 

CC              := $(CC_$(HOST))
DEBUG           := 
CFLAGS          := $(CFLAGS_$(HOST)) $(DEBUG) -D$(HOST) -pthread
CCOPT           := $(CCOPT_$(HOST))
SOOPT           := $(SOOPT_$(HOST))

BEXES := $(EXES:%=$(BIN)/%)

.SUFFIXES : .h .c .o .a .so
.PHONY : all install
.SECONDARY : $(BEXES)

ALIBS  := $(LIBS:%=$(LIB)/lib%.a)
SOLIBS := $(ALIBS:%.a=%.so)
OBJS   := $(OBJS:%=$(LIB)/%)

$(LIB)/%.o : %.c
	$(CC) $(CCOPT) $(CFLAGS) -c $< -o $@


all : $(DIRS) $(ALIBS) $(SOLIBS) $(EXES)
	@make install

install : $(INSTALLED)

include $(TEMPLATES)/post.mk


ADAPATH   ?= $(HOME)/ada
CPATH     := $(ADAPATH)/c
REPOSIT   := $(ADAPATH)/reposit
USR       := $(ADAPATH)/usr
GNATPATH  := /shared/tools/exec/gnat/bin
PCRE_CFG  := pcre-config
PCRE_INCL := `$(PCRE_CFG) --cflags`
PCRE_LIB  := `$(PCRE_CFG) --prefix`/lib/$(ARCH)
PCRE_LIBS := pcre
PCRE_ALIBS := $(PCRE_LIBS:%=$(PCRE_LIB)/lib%.a)


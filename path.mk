ADAPATH   ?= $(HOME)/ada
CPATH     := $(ADAPATH)/c
REPOSIT   := $(ADAPATH)/reposit
USR       := $(ADAPATH)/usr
GNATPATH  := /usr/local/gnat/bin
PCRE_CFG  := pcre-config
PCRE_INCL := `$(PCRE_CFG) --cflags`
PCRE_LIB  := `$(PCRE_CFG) --prefix`/lib/$(ARCH)

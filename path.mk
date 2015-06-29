ADAPATH   ?= $(HOME)/ada
CPATH     := $(ADAPATH)/c
REPOSIT   := $(ADAPATH)/reposit
USR       := $(ADAPATH)/usr
GNATPATH  := /usr/local/gnat/bin

PCRE ?= PCRE1
CFLAGS    := -D$(PCRE)
ifeq ($(PCRE),PCRE0)
PCRE_CFG  := pcre-config
PCRE_LIBS := pcre
else ifeq ($(PCRE),PCRE1)
PCRE_CFG  := pcre-config
PCRE_LIBS := pcreposix pcre
else
PCRE_CFG  := pcre2-config
PCRE_LIBS := pcre2-posix pcre2-8
endif
PCRE_INCL := `$(PCRE_CFG) --cflags`
PCRE_LIB  := `$(PCRE_CFG) --prefix`/lib/$(ARCH)


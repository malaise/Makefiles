CLEAN_EXES := $(EXES:%=clean_%)
.PHONY : afpx clean_afpx clean clean_exe $(CLEAN_EXES) clean_all new \
         scratch clean_html texi txt clean_texi clean_txt gpr

# Sub dirs
ifdef BIN
$(BIN) :
	@$(ECHO) MKDIR $@
	@$(MKDIR) $@
endif
ifdef LIB
$(LIB) :
	@$(ECHO) MKDIR $@
	@$(MKDIR) $@
endif

# Local exes
ifdef EXES
% : $(BIN)/%
	@$(LN) $< $@

$(EXES) : $(BEXES)
	@$(LN) $(BIN)/$@
endif

# Afpx stuff
ifeq ($(AFPX),true)
ifdef AFPX_XREF
AFPX_XREF_FILE := $(AFPX_XREF).ads
AFPX_BLD_OPT := -x$(AFPX_XREF)
AFPX_BLD_MSG := -x
endif
AFPX_FILES := AFPX.DSC AFPX.FLD AFPX.INI $(AFPX_XREF_FILE)
afpx : $(AFPX_FILES)

$(AFPX_FILES) : Afpx.xml
	@$(ECHO) AFPX_BLD $(AFPX_BLD_MSG)
	@afpx_bld $(AFPX_BLD_OPT) > /dev/null

clean_afpx :
	@$(ECHO) RM AFPX
	@$(RM) $(AFPX_FILES)
else
afpx :;

clean_afpx :;

endif

ifdef TEXI
TEXI_TARGETS := $(TEXI:=.info) $(TEXI:=.text)
.SUFFIXES : .texi .info .text
texi: $(TEXI_TARGETS)

WIDTH = 78

%.info : %.texi
	@echo DOC
	@makeinfo -f $(if $($(basename $<)_WIDTH), $($(basename $<)_WIDTH), $(WIDTH)) \
                 -o $@ $<

%.text : %.texi
	@echo DOC
	@makeinfo -f $(if $($(basename $<)_WIDTH), $($(basename $<)_WIDTH), $(WIDTH)) \
                 --plaintext -o $@ $<

clean_texi :
	@rm -f $(TEXI_TARGETS)
endif

ifdef TXT
TXT_TARGETS := $(TXT:=.html)
.SUFFIXES : .txt .html
txt: $(TXT_TARGETS)

%.html : %.txt
	@echo DOC
	@asciidoc -a numbered $(DOCOPTS_$(*F)) -o $@ $<

clean_txt :
	@rm -f $(TXT_TARGETS)
endif

# Clean stuff
clean : clean_gpr
	@$(ECHO) RM $(LIB)
	@$(RM) -r $(LIB)
	@$(RM) b~*
ifdef LINKFROM
	$(RM) $(FILES2LINK)
endif

clean_exe : clean_git
	@$(ECHO) RM $(BIN) EXEs
	@$(RM) -r $(BIN)
	@$(RM) $(EXES)

$(CLEAN_EXES) :
	@$(RM) $(LIB)/$(@:clean_%=%).o $(BIN)/$(@:clean_%=%) $(@:clean_%=%) 
	@if [ -f $(LIB)/$(@:clean_%=%).ali ] ; then \
	  $(RM) $(LIB)/$(@:clean_%=%).ali; \
	fi

new : clean_exe
	@$(MAKE)  $(NOPRTDIR)

scratch : clean_all
	@$(MAKE)  $(NOPRTDIR)

# Html stuff
clean_html :
	@if [ -d html ] ; then \
	  $(ECHO) RM html; \
	  $(RM) -r html; \
	fi

html : $(wildcard *.ad?)
	@$(MAKE) clean_html
	@$(GNATHTML) $(GNATHTMLOPT) *.ad?

# Make gps project
gpr :
ifdef ADAVIEW
	@SRCS="@.@"; \
	for dir in $(ADAVIEW) ; do \
	  SRCS="$$SRCS, @$$dir@"; \
	done; \
	$(ECHO) -e "project Ada is\n  for Source_Dirs use ("$$SRCS");\nend Ada;" \
	  | $(SED) -e 's/@/"/g' > ada.gpr
endif

clean_gpr :
ifdef ADAVIEW
	@$(RM) ada.gpr
endif

# Include any local makefile: cdep.mk...
LOCAL_MAKEFILES := $(wildcard *.mk)
ifneq ($(LOCAL_MAKEFILES),)
include $(LOCAL_MAKEFILES)
endif


CLEAN_EXES := $(EXES:%=clean_%)
.PHONY : afpx clean_afpx clean clean_exe $(CLEAN_EXES) clean_all new \
         scratch html clean_html

# Sub dirs
$(BIN) :
	$(MKDIR) $@

$(LIB) :
	$(MKDIR) $@

# Local exes
ifdef EXES
% : $(BIN)/%
	@$(LN) $< $@

$(EXES) : $(BEXES)
	@$(LN) $(BIN)/$@
endif

# Afpx stuff
ifeq ($(AFPX),true)
AFPX_FILES := AFPX.DSC AFPX.FLD AFPX.INI
afpx : $(AFPX_FILES)

$(AFPX_FILES) :: AFPX.LIS
	afpx_bld

clean_afpx :
	$(RM) $(AFPX_FILES)
else
afpx :;

clean_afpx :;

endif

# Clean stuff
clean :
	$(RM) -r $(LIB)
	@$(RM) b~*

clean_exe :
	$(RM) -r $(BIN)
	$(RM) $(EXES)

$(CLEAN_EXES) :
	@$(RM) $(LIB)/$(@:clean_%=%).o $(BIN)/$(@:clean_%=%) $(@:clean_%=%) 
	@if [ -f $(LIB)/$(@:clean_%=%).ali ] ; then \
	  $(RM)  $(LIB)/$(@:clean_%=%).ali; \
	fi

clean_all : clean clean_exe clean_afpx

new : clean_exe
	@$(MAKE)  $(NOPRTDIR)

scratch : clean_all
	@$(MAKE)  $(NOPRTDIR)

# Html stuff
html : clean_html
	@$(GNATHTML) $(GNATHTMLOPT) *.ad?

clean_html :
	$(RM) -r html

# Include any local makefile: cdep.mk...
MAKEFILES := $(wildcard *.mk)
ifneq ($(MAKEFILES),)
include $(MAKEFILES)
endif


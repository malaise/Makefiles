.PHONY: afpx clean clean_exe clean_all

# Sub dirs
$(BIN) :
	$(MKDIR) $@
	$(MAKE)

$(LIB) :
	$(MKDIR) $@
	$(MAKE)

# Link exe
$(BIN)/% : %
	$(LN) $(BIN)/* .

# Afpx stuff
ifdef AFPX
AFPX_FILES := AFPX.DSC AFPX.FLD AFPX.INI
afpx : $(AFPX_FILES)

$(AFPX_FILES) : AFPX.LIS
	afpx_bld

clean_afpx :
	$(RM) $(AFPX_FILES)
else
afpx:
clean_afpx :
endif

# Clean stuff
clean :
	$(RM) $(LIB)/* b~*

clean_exe :
	$(RM) $(BIN)/* $(notdir $(EXES))

clean_all : clean clean_exe clean_afpx


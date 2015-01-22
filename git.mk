.PHONY : git clean_git

git: .gitignore

.gitignore:
	@if [ -f .gitignore.ref ] ; then \
	  $(CP) .gitignore.ref .gitignore; \
	else \
	  $(TOUCH) .gitignore; \
	fi; \
	$(ECHO) $(EXES) $(FILES2LINK) $(GITIGNORE) $(TEXI_TARGETS) \
	  $(TXT_TARGETS) $(AFPX_XREF_FILE) $(CDEP) | $(SED) -e "s/ /\n/g" >> .gitignore; \
	$(ECHO) $(patsubst %.aps,%.ads,$(wildcard *.aps)) \
	         $(patsubst %.apb,%.adb,$(wildcard *.apb)) >> .gitignore;

clean_git:
	@$(RM) .gitignore


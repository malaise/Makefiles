.PHONY : git clean_git

git: .gitignore

.gitignore:
	@if [ -f .gitignore.ref ] ; then \
	  $(CP) .gitignore.ref .gitignore; \
	else \
	  $(TOUCH) .gitignore; \
	fi
	@$(ECHO) $(EXES) $(FILES2LINK) $(GITIGNORE) $(TEXI_TARGETS) | $(SED) -e "s/ /\n/g" >> .gitignore

clean_git:
	@$(RM) .gitignore


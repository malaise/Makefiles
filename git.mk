.PHONY : git clean_git

git: .gitignore

.gitignore:
	@$(ECHO) $(EXES) $(FILES2LINK) $(GITIGNORE) | $(SED) -e "s/ /\n/g" > .gitignore

clean_git:
	@$(RM) .gitignore


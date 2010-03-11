git: .gitignore

.gitignore:
	@$(ECHO) $(EXES) $(FILES2LINK) | $(SED) -e "s/ /\n/g" > .gitignore

clean_git:
	@$(RM) .gitignore


TARGETS := all clean clean_exe clean_all html
.PHONY : $(SUBDIRS) $(TARGETS)

$(TARGETS) :
ifneq ($(SUBDIRS),)
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit $$?; done
endif


TARGETS := all afpx clean clean_exe clean_afpx clean_all html clean_html
.PHONY : $(SUBDIRS) $(TARGETS)

$(TARGETS) :
ifneq ($(SUBDIRS),)
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit $$?; done
endif


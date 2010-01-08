TARGETS := all afpx lsdep echoadaview clean clean_exe clean_afpx clean_all new scratch install cdep dep clean_cdep clean_dep html clean_html
.PHONY : $(SUBDIRS) $(TARGETS)

$(TARGETS) :
ifneq ($(SUBDIRS),)
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit $$?; done
endif


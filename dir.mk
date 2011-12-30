ifneq ($(LOCAL_DIR),true)
# Normal invocation: recusive then local
TARGETS := all afpx lsdep echoadaview clean clean_exe clean_afpx clean_all \
           new scratch install cdep dep clean_cdep clean_dep html clean_html \
           texi txt clean_texi clean_txt gpr
.PHONY : $(SUBDIRS) $(TARGETS)

$(TARGETS) :
	 $(MAKE) LOCAL_DIR=true $@
ifneq ($(SUBDIRS),)
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit $$?; done
endif
else
# Local targets
.PHONY : all clean_all
all : texi txt git
clean_all : clean_texi clean_txt clean_git
include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk
endif

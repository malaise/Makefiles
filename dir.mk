ifneq ($(LOCAL_DIR),true)
# Normal invocation: local then recursive
TARGETS := all afpx echoadaview clean clean_exe clean_afpx clean_all \
           new scratch install dep clean_dep html clean_html \
           adactl clean_adactl texi txt clean_texi clean_txt test gpr metrics
.PHONY : $(SUBDIRS) $(TARGETS) local

$(TARGETS) :
	 $(MAKE) LOCAL_DIR=true $@
ifneq ($(SUBDIRS),)
	@for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit $$?; done
endif
else
# Local targets
.PHONY : all clean_all test
all : texi txt git
clean_all : clean_texi clean_txt clean_git
TEST := NONE
test :
include $(TEMPLATES)/post.mk
include $(TEMPLATES)/git.mk
endif

local :
	$(MAKE) LOCAL_DIR=true


MSIFORCE_RESOURCE = msiforce_resource
MSISYNC_TO_ARCHIVE = msisync_to_archive

MAKEFLAGS += --no-print-directory

LIBS = \
       $(MSIFORCE_RESOURCE) \
       $(MSISYNC_TO_ARCHIVE) 

.PHONY: all $(LIBS) clean
all: $(LIBS)

$(LIBS):
	@$(MAKE) -C $@;

clean:
	@$(MAKE) -C $(MSIFORCE_RESOURCE) clean;
	@$(MAKE) -C $(MSISYNC_TO_ARCHIVE) clean;



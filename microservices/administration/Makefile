MSIFORCE_RESOURCE = msiforce_resource
MSISYNC_TO_ARCHIVE = msisync_to_archive
MSIFREE_MICROSERVICE_OUT = msifree_microservice_out

MAKEFLAGS += --no-print-directory

LIBS = \
       $(MSIFORCE_RESOURCE) \
       $(MSISYNC_TO_ARCHIVE) \
       $(MSIFREE_MICROSERVICE_OUT)

.PHONY: all $(LIBS) clean
all: $(LIBS)

$(LIBS):
	@$(MAKE) -C $@;

clean:
	@$(MAKE) -C $(MSIFORCE_RESOURCE) clean;
	@$(MAKE) -C $(MSISYNC_TO_ARCHIVE) clean;
	@$(MAKE) -C $(MSIFREE_MICROSERVICE_OUT) clean;

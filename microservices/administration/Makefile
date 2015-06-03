MSIFORCE_RESOURCE = msiforce_resource

MAKEFLAGS += --no-print-directory

LIBS = \
       $(MSIFORCE_RESOURCE) \

.PHONY: all $(LIBS) clean
all: $(LIBS)

$(LIBS):
	@$(MAKE) -C $@;

clean:
	@$(MAKE) -C $(MSIFORCE_RESOURCE) clean;



MSIGET_IMAGE_META = msiget_image_meta

MAKEFLAGS += --no-print-directory

LIBS = \
       $(MSIGET_IMAGE_META)

.PHONY: all $(LIBS) clean
all: $(LIBS)

$(LIBS):
	@$(MAKE) -C $@;

clean:
	@$(MAKE) -C $(MSIGET_IMAGE_META) clean;



MSIPUT_DATAOBJ_OR_COLL   = msiput_dataobj_or_coll
MSIFILESYSTEM_RENAME = msifilesystem_rename
MSIGET_FILEPATHS_FROM_GLOB = msiget_filepaths_from_glob
MSIGET_IMAGE_META = msiget_image_meta

MAKEFLAGS += --no-print-directory

LIBS = \
       $(MSIGET_IMAGE_META) \
       $(MSIPUT_DATAOBJ_OR_COLL) \
       $(MSIFILESYSTEM_RENAME) \
       $(MSIGET_FILEPATHS_FROM_GLOB)

.PHONY: all $(LIBS) clean
all: $(LIBS)

$(LIBS):
	@$(MAKE) -C $@;

clean:
	@$(MAKE) -C $(MSIGET_IMAGE_META) clean;
	@$(MAKE) -C $(MSIPUT_DATAOBJ_OR_COLL) clean;
	@$(MAKE) -C $(MSIFILESYSTEM_RENAME) clean;
	@$(MAKE) -C $(MSIGET_FILEPATHS_FROM_GLOB) clean;



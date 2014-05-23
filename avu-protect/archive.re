# Prevent deletion of files having an AVU indicating the the file is
# an archive.

# Note that the acDataDeletePolicy { } rule in core.re must be
# commented out for this to work. If it is not commented out, then
# this rule will fail as it should but then the empty rule in core
# will execute, removing the file.

acDataDeletePolicy {
  *A = SELECT META_DATA_ATTR_VALUE WHERE DATA_ID = '$dataId' AND META_DATA_ATTR_NAME = 'http://testzone01/irods#archive' AND META_DATA_ATTR_VALUE = 'true';
  foreach(*Row in *A) {
    failmsg(-1, "Rejected deletion of $objPath ($dataId) with archive indicator set.");
    msiDeleteDisallowed;
  }
}

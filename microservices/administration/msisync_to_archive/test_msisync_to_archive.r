test_msi_sync_to_archive {

    *err = errormsg(
               msisync_to_archive(
                   "comp_resc;cache_resc",
                   "/tmp/cache_resc/home/rods/file1",
                   "/tempZone/home/rods/file1" ),
                   *msg );
    if( 0 != *err ) {
        writeLine( "stdout", "Error - [*msg], *err" );
    } else {
        writeLine( "stdout", "success?" );
    }

}

INPUT null
OUTPUT ruleExecOut


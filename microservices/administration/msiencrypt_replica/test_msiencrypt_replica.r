test_msiencrypt_replica {
    *err = 0;
    if(0 == *FLAG) {
        *enc_path = *PATH ++ ".UNencrypted";
    }
    else {
        *enc_path = *PATH ++ ".encrypted";
    }

    msiencrypt_replica(
       *PATH,                              # source path
       *enc_path,                          # destination path
       "TEMPORARY_32byte_encryption__key", # 32 byte encryption key
       "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", # 32 byte initialization vector
       *FLAG )

    if( 0 == *err ) {
        writeLine( "stdout", "output location: *enc_path" );
    } 
    else {
        writeLine( "stdout", "error [*err]" );
    }
}
#INPUT *PATH="/var/lib/irods/iRODS/Vault/home/rods/file0.encrypted", *FLAG=0
INPUT *PATH="/var/lib/irods/iRODS/Vault/home/rods/file0", *FLAG=1
OUTPUT ruleExecOut

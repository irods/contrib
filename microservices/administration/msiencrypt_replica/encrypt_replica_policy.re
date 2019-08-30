##################################################
# Helper Functions


# Single point of truth for an error value
get_error_value(*err) { *err = "ERROR_VALUE" }


# Single point of truth for the encryption key
get_key(*key) {
    *key = "TEMPORARY_32byte_encryption__key"
}


# Single point of truth for the initialization vector
get_iv(*iv) {
    *iv = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}


# Single point of truth for replica encryption attribute
get_encrypt_replica_attribute(*attr) {
    *attr = "irods::encryption::replica_encrypted"
}


# Single point of truth for encrypt attribute
get_encrypt_replica_attribute(*attr) {
    *attr = "irods::encryption::encrypt"
}


# get the physical path from the catalog given logical path an resource hierarchy
get_physical_path(*logical_path, *resource_hierarchy, *physical_path) {
    get_error_value(*physical_path)

    *ec = errormsg(msiSplitPath(*logical_path, *coll_name, *data_name), *msg)
    if(*ec < 0) {
        *msg = "Failed to split path [*logical_path]"
        writeLine("serverLog", *msg)
        failmsg(*ec, *msg)
    }

    foreach(*r in SELECT DATA_PATH where DATA_NAME = "*data_name" and COLL_NAME = "*coll_name" and DATA_RESC_HIER = "*resource_hierarchy") {
        *physical_path = *r.DATA_PATH
    }
} # get_physical_path


# there is no hierarchy available on the pre pep for get, look for a metadata flag instead
get_resource_hierarchy(*logical_path, *resource_hierarchy) {
    get_error_value(*resource_hierarchy)
    get_encrypt_replica_attribute(*attr)

    *ec = errormsg(msiSplitPath(*logical_path, *coll_name, *data_name), *msg)
    if(*ec < 0) {
        *msg = "Failed to split path [*logical_path]"
        writeLine("serverLog", *msg)
        failmsg(*ec, *msg)
    }

    foreach(*r in SELECT META_DATA_ATTR_VALUE where DATA_NAME = "*data_name" and COLL_NAME = "*coll_name" and META_DATA_ATTR_NAME = "*attr") {
        *resource_hierarchy = *r.META_DATA_ATTR_VALUE
    }

} # get_resource_hierarchy


# encrypt or decrypt the data at rest into a new file, then move that file over the
# replica in the file system, this prevents the need to update the catalog
encrypt_or_decrypt_object_replica(*logical_path, *resource_hierarchy, *encryption_flag) {
    get_error_value(*error_value)

    get_physical_path(*logical_path, *resource_hierarchy, *physical_path)
    if(*physical_path == *error_value) {
        *msg = "Failed to get physical path for [*logical_path] at [*resource_hierarchy]"
        writeLine("serverLog",  *msg)
        failmsg(-1, *msg)
    }

    *new_physical_path = *physical_path ++ ".msiencrypt_replica_output"

    get_key(*key)
    get_iv(*iv)

    *ec = errorcode( msiencrypt_replica(
                         *physical_path,     # source path
                         *new_physical_path, # destination path
                         *key,               # 32 byte encryption key
                         *iv,                # 32 byte initialization vector
                         *encryption_flag )) # encrypt or decrypt
    if(*ec < 0) {
        *msg = "Failed in msiencrypt_replica for [*logical_path] at [resource_hierarchy]"
        writeLine("serverLog",  *msg)
        failmsg(*ec, *msg)
    }

    *ec = errorcode(msiExecCmd("move_file.sh", "*new_physical_path *physical_path", 0, 0, 0, *out))
    if(*ec < 0) {
        *msg = "Failed in msiExecCmd for [*new_physical_path] at [*physical_path]"
        writeLine("serverLog",  *msg)
        failmsg(*ec, *msg)
    }

} # encrypt_or_decrypt_object_replica


##################################################
# Policy Enforcement Points


pep_api_data_obj_put_post(*INSTANCE_NAME, *COMM, *DATAOBJINP, *BUFFER, *PORTAL_OPR_OUT) {
    *logical_path       = *DATAOBJINP.obj_path
    *resource_hierarchy = *DATAOBJINP.resc_hier
    encrypt_or_decrypt_object_replica(*logical_path, *resource_hierarchy, 1)

} # pep_api_data_obj_put_post


pep_api_data_obj_get_pre(*INSTANCE_NAME, *COMM, *DATAOBJINP, *PORTAL_OPR_OUT, *BUFFER) {
    get_error_value(*error_value)

    *logical_path = *DATAOBJINP.obj_path

    *ec = errorcode(get_resource_hierarchy(*logical_path, *resource_hierarchy))
    if(*ec == 0 && *error_value != *resource_hierarchy) {
        encrypt_or_decrypt_object_replica(*logical_path, *resource_hierarchy, 0)
    }

} # pep_api_data_obj_get_pre


pep_api_data_obj_get_post(*INSTANCE_NAME, *COMM, *DATAOBJINP, *PORTAL_OPR_OUT, *BUFFER) {
    get_error_value(*error_value)

    *logical_path = *DATAOBJINP.obj_path

    *ec = errorcode(get_resource_hierarchy(*logical_path, *resource_hierarchy))
    if(*ec == 0 && *error_value != *resource_hierarchy) {
        encrypt_or_decrypt_object_replica(*logical_path, *resource_hierarchy, 1)
    }

} # pep_api_data_obj_get_post



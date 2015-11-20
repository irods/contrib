// =-=-=-=-=-=-=-
#include "apiHeaderAll.hpp"
#include "msParam.hpp"
#include "reGlobalsExtern.hpp"
#include "irods_ms_plugin.hpp"
#include "irods_file_object.hpp"
#include "irods_resource_redirect.hpp"

// =-=-=-=-=-=-=-
#include <string>
#include <iostream>
#include <vector>

extern "C" {

    double get_plugin_interface_version() {
        return 1.0;
    }

    int msisync_to_archive(
        msParam_t*      _resource_hierarchy,
        msParam_t*      _physical_path,
        msParam_t*      _logical_path,
        ruleExecInfo_t* _rei ) {
        using std::cout;
        using std::endl;
        using std::string;
        char *resource_hierarchy = parseMspForStr( _resource_hierarchy );
        if( !resource_hierarchy ) {
            cout << "msisync_to_archive - null _resc_hier parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }
        
        char *physical_path = parseMspForStr( _physical_path );
        if( !physical_path ) {
            cout << "msisync_to_archive - null _physical_path parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }
        
        char *logical_path = parseMspForStr( _logical_path );
        if( !logical_path ) {
            cout << "msisync_to_archive - null _logical_path parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        if( !_rei ) {
            cout << "msisync_to_archive - null _rei parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        irods::file_object_ptr file_obj(
            new irods::file_object(
                _rei->rsComm,
                logical_path,
                physical_path,
                resource_hierarchy,
                0,     // fd
                0,     // mode
                0 ) ); // flags

        const keyValPair_t& kvp = file_obj->cond_input();
        addKeyVal(
            (keyValPair_t*)&kvp,
            ADMIN_KW,
            "true" );
        // inform the resource that a write operation happened
        // to put it in a state where it will need to replicate
        irods::error ret = fileNotify(
                _rei->rsComm,
                file_obj,
                irods::WRITE_OPERATION );
        if( !ret.ok() ) {
            cout << "msisync_to_archive - fileNotify failed ["
                 << ret.result().c_str() << "] - ["
                 << ret.code() << "]" << endl;
            return ret.code();
        }

        // inform the resource that a modification is complete
        // which will trigger the replication
        ret = fileModified(
                _rei->rsComm,
                file_obj );
        if( !ret.ok() ) {
            cout << "msisync_to_archive - fileModified failed ["
                 << ret.result().c_str() << "] - ["
                 << ret.code() << "]" << endl;
            return ret.code();
        }

        return 0; 

    }

    irods::ms_table_entry* plugin_factory() {
        irods::ms_table_entry* msvc = new irods::ms_table_entry(3);
        msvc->add_operation("msisync_to_archive", "msisync_to_archive");
        return msvc;
    }

} // extern "C"


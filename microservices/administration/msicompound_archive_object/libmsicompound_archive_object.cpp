// =-=-=-=-=-=-=-
#include "apiHeaderAll.hpp"
#include "msParam.hpp"
#include "reGlobalsExtern.hpp"
#include "irods_ms_plugin.hpp"
#include "irods_file_object.hpp"
#include "irods_resource_redirect.hpp"
#include "irods_hierarchy_parser.hpp"

// =-=-=-=-=-=-=-
#include <string>
#include <iostream>
#include <vector>

extern "C" {

    double get_plugin_interface_version() {
        return 1.0;
    }

    irods::error find_compound_resource_in_hierarchy(
            const std::string&   _hier,
            irods::resource_ptr& _resc ) {

        irods::hierarchy_parser p;
        irods::error ret = p.set_string( _hier );
        if( !ret.ok() ) {
            return PASS( ret );
        }

        std::string last;
        ret = p.last_resc( last );
        if( !ret.ok() ) {
            return PASS( ret );
        }

        bool found = false;
        std::string prev;
        irods::hierarchy_parser::const_iterator itr;
        for( itr = p.begin(); itr != p.end(); ++itr ) {
            if( *itr == last ) {
                found = true;
                break;
            }
            prev = *itr;
        }

        if( !found ) {
            std::string msg = "Previous child not found for [";
            msg += _hier;
            msg += "]";
            return ERROR(
                    CHILD_NOT_FOUND,
                    msg );
        }

        ret = resc_mgr.resolve( prev, _resc );
        if( !ret.ok() ) {
            return PASS( ret );
        }

        return SUCCESS();
    }

    int msicompound_archive_object(
        msParam_t*      _resource_hierarchy,
        msParam_t*      _logical_path,
        msParam_t*      _physical_path,
        ruleExecInfo_t* _rei ) {
        using std::cout;
        using std::endl;
        using std::string;
        char *resource_hierarchy = parseMspForStr( _resource_hierarchy );
        if( !resource_hierarchy ) {
            cout << __FUNCTION__ << " - null _resc_hier parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        char *logical_path = parseMspForStr( _logical_path );
        if( !logical_path ) {
            cout << __FUNCTION__ << " - null _logical_path parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        char *physical_path = parseMspForStr( _physical_path );
        if( !logical_path ) {
            cout << __FUNCTION__ << " - null _logical_path parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        if( !_rei ) {
            cout << __FUNCTION__ << " - null _rei parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        // get root resc to
        irods::resource_ptr resc; 
        irods::error ret = find_compound_resource_in_hierarchy(
                               resource_hierarchy,
                               resc );
        if( !ret.ok() ) {
            return ret.code();
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

        ret = resc->call( _rei->rsComm, "resource_archive_object", file_obj);
        if( !ret.ok() ) {
            irods::log( PASS( ret ) );
            return ret.code();
        }

        return 0; 

    }

    irods::ms_table_entry* plugin_factory() {
        irods::ms_table_entry* msvc = new irods::ms_table_entry(3);
        msvc->add_operation("msicompound_archive_object", "msicompound_archive_object");
        return msvc;
    }

} // extern "C"


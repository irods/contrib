// =-=-=-=-=-=-=-
#include "apiHeaderAll.hpp"
#include "msParam.hpp"
#include "reGlobalsExtern.hpp"
#include "irods_ms_plugin.hpp"

// =-=-=-=-=-=-=-
#include <string>
#include <iostream>
#include <vector>

extern "C" {
    int msiforce_resource(msParam_t* _resc_name, ruleExecInfo_t* _rei) {
        using std::cout;
        using std::endl;
        using std::string;

        char *resc_name = parseMspForStr( _resc_name );
        if( !resc_name ) {
            cout << "msiforce_resource - null _resc_name parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        if( !_rei ) {
            cout << "msiforce_resource - null _resc_name parameter" << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        snprintf( _rei->rescName, NAME_LEN, "%s", resc_name );

        // Done
        return 0; 

    }

    irods::ms_table_entry* plugin_factory() {
        irods::ms_table_entry* msvc = new irods::ms_table_entry(1);
        msvc->add_operation("msiforce_resource", "msiforce_resource");
        return msvc;
    }

} // extern "C"


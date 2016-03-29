// =-=-=-=-=-=-=-
// irods includes
#include "apiHandler.hpp"
#include "irods_stacktrace.hpp"
#include "irods_server_api_call.hpp"
#include "irods_re_serialization.hpp"
#include "boost/lexical_cast.hpp"
#include "irods_api_calling_functions.hpp"

#include "objStat.h"
#include "rodsPackInstruct.h"

// =-=-=-=-=-=-=-
// stl includes
#include <sstream>
#include <string>
#include <iostream>

// =-=-=-=-=-=-=-
// api function to be referenced by the entry
int rs_zookeeper_unlock( rsComm_t* _comm, dataObjInp_t* _inp ) {

    rodsLog( LOG_NOTICE, "XXXX - %s", __FUNCTION__ );

    return 0;
}

extern "C" {
    // =-=-=-=-=-=-=-
    // factory function to provide instance of the plugin
    irods::api_entry* plugin_factory(
        const std::string&,     //_inst_name
        const std::string& ) { // _context
        // =-=-=-=-=-=-=-
        // create a api def object
        irods::apidef_t def = { DATA_OBJ_UNLOCK_AN,            // api number
                                RODS_API_VERSION,              // api version
                                REMOTE_USER_AUTH,              // client auth
                                REMOTE_PRIV_USER_AUTH,         // proxy auth
                                "DataObjInp_PI", 0,            // in PI / bs flag
                                NULL, 0,                       // out PI / bs flag
                                boost::any(std::function<
                                    int(rsComm_t*,dataObjInp_t*)>(
                                        rs_zookeeper_unlock)), // the operation
								"data_obj_unlock",             // operation name
                                clearDataObjInp,               // null clear fcn
                                (funcPtr)CALL_DATAOBJINP       // call handler
                              };
        // =-=-=-=-=-=-=-
        // create an api object
        irods::api_entry* api = new irods::api_entry( def );

        // =-=-=-=-=-=-=-
        // assign the pack struct key and value
        api->in_pack_key   = "DataObjInp_PI";
        api->in_pack_value = DataObjInp_PI;

        return api;

    } // plugin_factory

}; // extern "C"

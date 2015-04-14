#include "reFuncDefs.hpp"
#include "microservice.hpp"
#include "objInfo.hpp"
#include "reDataObjOpr.hpp"
#include "collCreate.hpp"

#include "boost/filesystem/operations.hpp"
#include "boost/filesystem/path.hpp"
namespace fs = boost::filesystem;

std::string get_filesystem_path(
    const std::string& _full_path,
    const std::string& _src,
    const std::string& _tgt ) {
   
    std::string logical_path = _full_path; 
    std::string::size_type pos = _full_path.find( _src );
    if( std::string::npos != pos ) {
       logical_path = _tgt + _full_path.substr( pos+_src.size() );
    
    } else {
        rodsLog( 
            LOG_DEBUG, 
            "get_filesystem_path :: src dir not found [%s] in [%s]", 
            _src.c_str(), 
            _full_path.c_str() );
    }

    rodsLog( 
        LOG_DEBUG, 
        "get_filesystem_path :: [%s]", 
        logical_path.c_str() );

    return logical_path;

} // get_filesystem_path



MICROSERVICE_BEGIN(
    msifilesystem_rename,
    STR,        _path, INPUT,
    STR,        _src,  INPUT,
    STR,        _tgt,  INPUT )
    RE_TEST_MACRO( "    Calling msifilesystem_rename" );

    std::string new_path = get_filesystem_path( 
                               _path,
                               _src,
                               _tgt );
    fs::rename( _path, new_path );
    
    RETURN( 0 )

// cppcheck-suppress syntaxError
MICROSERVICE_END

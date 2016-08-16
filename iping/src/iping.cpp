/*
 * iping - App that "pings" an iRODS server. 
*/

#include "rodsClient.h"
#include "parseCommandLine.h"
#include "rodsPath.h"
#include "lsUtil.h"


#include "irods_buffer_encryption.hpp"
#include "irods_client_api_table.hpp"
#include "irods_pack_table.hpp"
#include "boost/lexical_cast.hpp"

#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

void usage() {
    fprintf(stderr, "Usage: iping [-h <host>] [-p <port>]\n");
}

void invalidPortMessage() {
    fprintf(stderr, "Option -p requires a port which must be a positive integer from 1 to 65535.\n");
    usage();
}


int main( int argc, char **argv ) {

    signal( SIGPIPE, SIG_IGN );

    char *rodsHost = "localhost";
    char *rodsPortStr = "1247";
    int c;

    while ((c = getopt(argc, argv, "h:p:")) != -1) {
        switch(c) {
          case 'h':
            rodsHost = optarg;
            break; 
          case 'p':
            rodsPortStr = optarg;
            break;
          case '?':
            if (optopt == 'h') {
                usage();
            } else if (optopt == 'p') {
                usage();
            } else {
                usage();
            }
            return 2; 
        }     
    }


    int rodsPort = 0;
   
    rcComm_t *conn;
    rErrMsg_t errMsg;

    try {
        rodsPort = boost::lexical_cast<unsigned int>(rodsPortStr);
    } catch (boost::bad_lexical_cast& _e) {
        invalidPortMessage();
        return 2;
    }

    if (rodsPort < 1 || rodsPort > 65535) {
        invalidPortMessage();
        return 2; 
    }


    conn = rcConnect(rodsHost, rodsPort, "", "", 0, &errMsg );

    if (conn == NULL) {
        return 2;
    }

    printf("OK : connection to iRODS server successful\n");  
    rcDisconnect( conn );
    return 0;
}


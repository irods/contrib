GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost/

all: libmsiget_filepaths_from_glob

LIBS = /usr/lib/libirods_client.a /usr/lib/irods/externals/libboost_filesystem.a  /usr/lib/irods/externals/libboost_regex.a /usr/lib/irods/externals/libboost_system.a  /usr/lib/irods/externals/libboost_thread.a  /usr/lib/irods/externals/libboost_chrono.a

libmsiget_filepaths_from_glob:
	${GCC} ${INC} -DRODS_SERVER -fPIC -shared -g -Wno-deprecated -o $@.so $@.cpp ${LIBS}

clean:
	@rm -f ./*.so

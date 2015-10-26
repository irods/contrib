GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost

all: libmsisync_to_archive

libmsisync_to_archive:
	${GCC} ${INC} -DRODS_SERVER -fPIC "-Wl,-E" -shared -g -Wno-deprecated -rdynamic -o $@.so $@.cpp
     

clean:
	@rm -f ./*.so

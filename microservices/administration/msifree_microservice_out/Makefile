GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost

.PHONY: all clean

all: libmsifree_microservice_out

libmsifree_microservice_out:
	${GCC} ${INC} -DRODS_SERVER -fPIC "-Wl,-E" -shared -g -Wno-deprecated -rdynamic -o $@.so $@.cpp

clean:
	@rm -f *.so

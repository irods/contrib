GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost/

all: libmsifilesystem_rename

libmsifilesystem_rename:
	${GCC} ${INC} -DRODS_SERVER -fPIC -shared -g -Wno-deprecated -o $@.so $@.cpp /usr/lib/libirods_client.a

clean:
	@rm -f ./*.so

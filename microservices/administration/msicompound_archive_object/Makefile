GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost

all: libmsicompound_archive_object

libmsicompound_archive_object:
	${GCC} ${INC} -DRODS_SERVER -fPIC "-Wl,-E" -shared -g -Wno-deprecated -rdynamic -o $@.so $@.cpp /usr/lib/libirods_server.a


     

clean:
	@rm -f ./*.so

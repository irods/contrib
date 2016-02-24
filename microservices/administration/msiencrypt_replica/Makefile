GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost

all: libmsiencrypt_replica

libmsiencrypt_replica:
	${GCC} ${INC} -DRODS_SERVER -fPIC "-Wl,-E" -shared -g -Wno-deprecated -rdynamic -o $@.so $@.cpp /usr/lib/libirods_client.a
     

clean:
	@rm -f ./*.so

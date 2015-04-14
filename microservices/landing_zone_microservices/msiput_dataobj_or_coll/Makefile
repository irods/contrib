GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost/

all: libmsiput_dataobj_or_coll

libmsiput_dataobj_or_coll:
	${GCC} ${INC} -DRODS_SERVER -fPIC -shared -g -Wno-deprecated -o $@.so $@.cpp /usr/lib/libirods_client.a

clean:
	@rm -f ./*.so

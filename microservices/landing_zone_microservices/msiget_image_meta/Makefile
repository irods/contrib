GCC = g++

INC=-I/usr/include/irods/ -I/usr/include/irods/boost/ -I/usr/include/ImageMagick

all: libmsiget_image_meta

libmsiget_image_meta:
	${GCC} ${INC} -DRODS_SERVER -fPIC "-Wl,-E" -shared -g -Wno-deprecated -rdynamic -o $@.so $@.cpp -lMagick++ /usr/lib/libirods_client.a
     

clean:
	@rm -f ./*.so

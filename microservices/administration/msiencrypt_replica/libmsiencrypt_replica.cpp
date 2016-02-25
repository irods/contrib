
#include "apiHeaderAll.hpp"
#include "msParam.hpp"
#include "reGlobalsExtern.hpp"
#include "irods_ms_plugin.hpp"

#include <string>
#include <vector>
#include <iostream>
#include <fstream>

#include <boost/filesystem.hpp>

/**
 * _source_path           - fully qualified physical path of the file to be encrypted/decrypted
 * _destination_path      - fully qualified physical path of the location to write
 * _encryption_key        - key used to encrypt / decrypt the file ( must be 32 characters )
 * _initialization_vector - salt used to start the encryption process ( must be same length as the key )
 * _encrypt_decrypt_flag  - flag to indicate operation: 1 - encrypt, 0 - decrypt
 * **/
extern "C" {
    int msiencrypt_replica(
        msParam_t* _source_path,
        msParam_t* _destination_path,
        msParam_t* _encryption_key,
        msParam_t* _initialization_vector,
        msParam_t* _encrypt_decrypt_flag,
        ruleExecInfo_t* _rei) {
        using std::cout;
        using std::endl;
        using std::ifstream;
        using std::ofstream;
        using std::string;
        namespace bfs = boost::filesystem;

        char* source_path = parseMspForStr( _source_path );
        if( !source_path ) {
            cout << __FUNCTION__
                 << " - first parameter is null"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        char* destination_path = parseMspForStr( _destination_path );
        if( !destination_path ) {
            cout << __FUNCTION__
                 << " - second parameter is null"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        unsigned char* encryption_key = reinterpret_cast<unsigned char*>( parseMspForStr( _encryption_key ) );
        if( !encryption_key ) {
            cout << __FUNCTION__
                 << " - third parameter is null"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        unsigned char* initialization_vector = reinterpret_cast<unsigned char*>( parseMspForStr( _initialization_vector ) );
        if( !_initialization_vector ) {
            cout << __FUNCTION__
                 << " - fourth parameter is null"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        int encrypt_decrypt_flag = parseMspForPosInt( _encrypt_decrypt_flag );
        if( encrypt_decrypt_flag < 0 ) {
            cout << __FUNCTION__
                 << " - fifth parameter is invalid"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        if( !_rei ) {
            cout << __FUNCTION__
                 << " - null rei parameter"
                 << endl;
            return SYS_INVALID_INPUT_PARAM;
        }

        bfs::path p(source_path);
        if(!bfs::exists(p)) {
            cout << __FUNCTION__
                 << " - file does not exist ["
                 << source_path
                 << "]"
                 << endl;
            return SYS_INVALID_FILE_PATH;
        }

        ifstream f_in(source_path, ifstream::binary);
        if(!f_in.is_open()) {
            cout << __FUNCTION__
                 << " - file did not open for read ["
                 << source_path
                 << "]"
                 << endl;
            return SYS_INVALID_FILE_PATH;
        }

        ofstream f_out(destination_path, ofstream::binary|ofstream::trunc);
        if(!f_out.is_open()) {
            cout << __FUNCTION__
                 << " - file did not open for write ["
                 << destination_path
                 << "]"
                 << endl;
            return SYS_INVALID_FILE_PATH;
        }

        EVP_CIPHER_CTX ctx;
        EVP_CipherInit(
            &ctx,
            EVP_aes_256_cbc(),
            encryption_key,
            initialization_vector,
            encrypt_decrypt_flag);

        int out_len = 0;
        std::streamsize read_block_size = 4096;
        uint32_t cipher_block_size = EVP_CIPHER_CTX_block_size(&ctx);

        char* read_buffer = new char[read_block_size];
        unsigned char* cipher_buffer = new unsigned char[read_block_size + cipher_block_size];

        while( !f_in.eof() ) {
            f_in.read(read_buffer, read_block_size);
            if( !f_in.eof() && f_in.fail() ) {
                rodsLog(
                    LOG_ERROR,
                    "failed to read [%s]",
                    source_path );
                f_in.close();
                f_out.close();
                delete[] read_buffer;
                delete[] cipher_buffer;
                return UNIX_FILE_READ_ERR;
            }

            EVP_CipherUpdate(
                &ctx,
                cipher_buffer,
                &out_len,
                reinterpret_cast<unsigned char*>( read_buffer ),
                f_in.gcount());

            f_out.write(
                reinterpret_cast<char*>(cipher_buffer),
                out_len);
            if( f_out.fail() ) {
                rodsLog(
                    LOG_ERROR,
                    "failed to write [%s]",
                    source_path );
                f_in.close();
                f_out.close();
                delete[] read_buffer;
                delete[] cipher_buffer;
                return UNIX_FILE_WRITE_ERR;
            }

        } // while

        EVP_CipherFinal(
            &ctx,
            cipher_buffer,
            &out_len);

        f_out.write(
            reinterpret_cast<char*>(cipher_buffer),
            out_len);
        if( f_out.fail() ) {
            rodsLog(
                LOG_ERROR,
                "failed to write [%s]",
                source_path );
            return UNIX_FILE_WRITE_ERR;
        }

        f_in.close();
        f_out.close();
        delete[] read_buffer;
        delete[] cipher_buffer;

        return 0; 

    } // msiencrypt_replica

    irods::ms_table_entry* plugin_factory() {
        irods::ms_table_entry* msvc = new irods::ms_table_entry(5);
        msvc->add_operation("msiencrypt_replica", "msiencrypt_replica");
        return msvc;
    }

} // extern "C"


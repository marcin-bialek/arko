#include <stdio.h>
#include <stdlib.h>


extern int flipdiagbmp24(void* bmp, long size);


void displayInfo(void) {
    #if __x86_64__
        puts("[64-bit]");
    #else 
        puts("[32-bit]");
    #endif
}


long getFileSize(FILE* file) {
    fseek(file, 0, 2);
    long filesize = ftell(file);
    rewind(file);
    return filesize;
}


long loadFileToBuffer(const char* path, void** buffer) {
    FILE* file = NULL;
    
    if(!(file = fopen(path, "rb"))) {
        return -1;
    }
    
    size_t filesize = getFileSize(file);
    
    if(!(*buffer = malloc(filesize)) || !fread(*buffer, 1, filesize, file)) {
        free(*buffer);
        fclose(file);
        return -1;
    }
    
    fclose(file);
    return filesize;
}


int saveBufferToFile(const char* path, const void* buffer, long size) {
    FILE *file = NULL;
    
    if(!(file = fopen(path, "wb"))) {
        return -1;
    }

    if(fwrite(buffer, 1, size, file) != size) {
        fclose(file);
        return -1;
    }
    
    fclose(file);
    return 0;
}


int main(int argc, const char* argv[]) {
    long size;
    void* buffer = NULL;

    displayInfo();

    if(argc != 2) {
        fprintf(stderr, "usage: %s [path to BMP file]\n", argv[0]);
        goto error;
    }

    if((size = loadFileToBuffer(argv[1], &buffer)) == -1) {
        fputs("error: .bmp file does not exist or you have no permissions to read it\n", stderr);
        goto error;
    }

    switch(flipdiagbmp24(buffer, size)) {
        case 0: break;
        case -1: fputs("error: picture must be in bmp format\n", stderr); goto error;
        case -2: fputs("error: number of bits per pixel must be 24\n", stderr); goto error;
        case -3: fputs("error: picture must be square (width = height)\n", stderr); goto error;
        case -4: fputs("error: broken .bmp file\n", stderr); goto error;
        default: fputs("error: unknown\n", stderr); goto error;
    }

    if(saveBufferToFile("out.bmp", buffer, size) == -1) {
        fputs("error: could not save output file\n", stderr);
        goto error;
    }

    puts("done");
    free(buffer);
    return 0;
error:
    free(buffer);
    return 1;
}


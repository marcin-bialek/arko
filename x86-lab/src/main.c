#include <stdio.h>
#include <stdlib.h>


extern char* swapln(char* s, unsigned int n);


int main(int argc, char* argv[]) {
    if(argc != 3) {
        return 1;
    }

    char* res = swapln(argv[1], atoi(argv[2]));
    printf("%s\n", res);

    return 0;
}
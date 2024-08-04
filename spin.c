#include <stdio.h>
int i;
char spin[4] = { '|', '/', '-', '\\' };
void main() {
	for(i=0;;usleep(300000), fflush(stdout))
		printf("%c\x08", spin[++i%4]);
}

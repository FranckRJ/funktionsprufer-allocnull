#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>

void	*malloc_null(size_t size)
{
	static time_t seed = 0;

	if (seed == 0)
	{
		seed = (CUSTOM_SEED == 0 ? time(NULL) : CUSTOM_SEED);
		srand(seed);
		dprintf(STDERR_FILENO, "Seed : %u\n", (unsigned)seed);
	}
	if (rand() % 100 < PERCENT_CHANCE_FAIL)
		return (NULL);
	else
		return (malloc(size));
}

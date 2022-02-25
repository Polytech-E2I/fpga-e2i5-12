// See LICENSE for license details.

#include "femto.h"
#include "arch/riscv/encoding.h"
#include "arch/riscv/machine.h"

extern char _bss_start;
extern char _bss_end;
extern char _memory_end;

int main(int argc, char **argv);

__attribute__((noreturn)) void libfemto_start_main()
{
	char *argv[] = { "femto", NULL };
#if 0
	memset(&_bss_start ,0 , &_bss_end - &_bss_start);
#else /* We know for sure that the addresses are word aligned
         and it is the only sb I got when compiling the apps
         with ENV_QEMU unset */
        for (uint32_t *x = (uint32_t *)&_bss_start;
              x < (uint32_t *)&_bss_end;
              x++)
           *x = 0;
#endif
	arch_setup();
	_malloc_addblock(&_bss_end, &_memory_end - &_bss_end);
	exit(main(1, argv));
	__builtin_unreachable();
}

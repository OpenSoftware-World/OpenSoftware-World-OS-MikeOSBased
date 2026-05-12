#include <mikeos.h>

int	MikeMain(void *argument)
{
	static char Buf[256];
	static char mikeos_api_version[16];
	static int  get_mikeos_api_version;

	mikeos_draw_background("System Information", "v1.2", 0x001f);

	mikeos_print_string("System Information for OpenSoftware-World OS (MikeOSBased) v1.3");
	mikeos_print_newline();

	mikeos_print_newline();
	mikeos_print_string("OS Name: OpenSoftware-World OS (MikeOSBased)");
	mikeos_print_newline();
	mikeos_print_string("OS Version: 1.3");
	mikeos_print_newline();
	mikeos_print_string("OS Base: MikeOS");
	mikeos_print_newline();
	mikeos_print_string("OS Base Version: 4.7.0");
	mikeos_print_newline();
	mikeos_print_string("OS Architecture: x86 (32-bit)");
	mikeos_print_newline();
	mikeos_print_string("OS Shell Version: 1.2");
	mikeos_print_newline();
	mikeos_print_string("System Information Version: 1.2");
	mikeos_print_newline();

	get_mikeos_api_version = mikeos_get_api_version();
	mikeos_int_to_string(mikeos_api_version, get_mikeos_api_version);

	mikeos_print_string("MikeOS API Version: ");
	mikeos_print_string(mikeos_api_version);
	mikeos_print_newline();

	mikeos_wait_for_key();

	return 0;
}

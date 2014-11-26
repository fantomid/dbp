#include <string.h>
#include <libgen.h>
#include <stdio.h>
#include "state.h"
#include "desktop.h"
#include "package.h"
#include "config.h"
#include "loop.h"

/* When calling any of these funtions, other threads must not exist. Else, things will blow up horribly */


/* time_t isn't 64-bit on all systems, although this will not be a major issue for a while... */
signed long long state_btime() {
	FILE *fp;
	signed long long t;
	
	if (!(fp = fopen("/proc/stat", "r")))
		return -1;
	while (!feof(fp)) {
		if (fscanf(fp, "btime %lli\n", &t) < 1)
			continue;
		fclose(fp);
		return t;
	}

	fclose(fp);
	return -1;
}


void state_dump(struct package_s *p) {
	struct desktop_file_s *df;
	char buff[16], buff2[16], *dirname_s, *dir;
	int i;

	fprintf(stderr, "*** Dumping state ***\n");
	
	df = desktop_parse("Type=DBPStateFile\n");

	desktop_section_new(df, "DBPStateControl");

	snprintf(buff, 16, "%lli", state_btime());
	desktop_entry_new(df, "SystemBootup", "", buff);
	snprintf(buff, 16, "%i", p->run_cnt);
	desktop_entry_new(df, "RunCnt", "", buff);
	desktop_section_new(df, "Instances");
	
	for (i = 0; i < p->instances; i++) {
		snprintf(buff, 16, "%i", p->instance[i].run_id);
		desktop_entry_new(df, "PkgId", buff, p->instance[i].package_id);
		snprintf(buff2, 16, "%i", p->instance[i].loop);
		desktop_entry_new(df, "Loop", buff, buff2);
	}
	
	dirname_s = strdup(config_struct.state_file);
	dir = dirname(dirname_s);
	loop_directory_setup(dir, 0700);
	free(dirname_s);
	desktop_write(df, config_struct.state_file);
	desktop_free(df);
	return;
}

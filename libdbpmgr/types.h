#ifndef __DBP_TYPES_H__
#define	__DBP_TYPES_H__

#include <stdbool.h>
#include <stdint.h>

/* XXX: No NOT add fields here, it will break the API */
enum DBPMgrDependVersionCheck {
	DBPMGR_DEPEND_VERSION_CHECK_LTEQ,
	DBPMGR_DEPEND_VERSION_CHECK_GTEQ,
	DBPMGR_DEPEND_VERSION_CHECK_LT,
	DBPMGR_DEPEND_VERSION_CHECK_EQ,
	DBPMGR_DEPEND_VERSION_CHECK_GT,
	DBPMGR_DEPEND_VERSION_CHECKS
};

struct DBPList {
	struct DBPList		*next;
	char			*id;
	char			*path;
	bool			on_desktop;
};


struct DBPDepend {
	char			*pkg_name;
	char			*version[DBPMGR_DEPEND_VERSION_CHECKS];
	char			*arch;
};


#endif

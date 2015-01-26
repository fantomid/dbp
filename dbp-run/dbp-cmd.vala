[CCode(cname="GETTEXT_PACKAGE")]
extern const string GETTEXT_PACKAGE;

void usage() {
	stdout.printf(_("Usage: dbp-cmd <command> [arg]\n"));
	stdout.printf(_("Executes a command dbpd system call\n"));
	stdout.printf(_("List of valid commands:\n"));
	stdout.printf(_("\tmount	- Mounts a package so that it can be executed. Takes pkgid.\n"));
	stdout.printf(_("\t		  Returns a token that you use to unmount the package\n"));
	stdout.printf(_("\tumount	- Unmounts the package if no other instance is using it. Takes mount token\n"));
	stdout.printf(_("\tgetmount	- Returns the mountpoint for the media the package is on. Takes pkgid\n"));
	stdout.printf(_("\tregister	- Register a package in the database. Takes path to package file\n"));
	stdout.printf(_("\tunregister	- Unregisters a package in the database. Takes path to package file\n"));
	stdout.printf(_("\tid		- Returns the pkgid for the package at <path>\n"));
	stdout.printf(_("\tpath		- Returns the path for the package with id <pkgid>\n"));
	stdout.printf(_("\tlist		- Lists all registered packages\n"));
	stdout.printf(_("\tping		- Pings dbpd, exits with a failure if dbpd isn't running\n"));
	stdout.printf("\n");
	stdout.printf(_("pkgid is a unique ID that every valid package has\n"));
	stdout.printf(_("A registered package have its executables and .desktop files exported\n"));
	return;
}
	
int main(string[] args) {
	string ret, ret2;

	Intl.setlocale(LocaleCategory.MESSAGES, "");
	Intl.textdomain(GETTEXT_PACKAGE); 
	Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8"); 
	
	if (args.length < 2) {
		usage();
		return 1;
	}

	try {
		bus = Bus.get_proxy_sync(BusType.SYSTEM, DBP.DBus.DAEMON_PREFIX, DBP.DBus.DAEMON_OBJECT);
	} catch(Error e) {
		stderr.printf (_("Error: %s\n"), e.message);
		return 1;
	}
	
	try {
		switch (args[1]) {
			case "mount":
				string user;
	
				user = GLib.Environment.get_variable("USER");
				if (user == null) {
					stderr.printf(_("Error: The enviroment variable $USER isn't set, it is needed\n"));
					return 1;
				}
	
				ret = bus.mount(args[2], user);
				if (int.parse(ret) < 0) {
					/* -1013 == already registered */
					if (ret == "-1013")
						return 0;
					/* TODO: Print error message */
					stdout.printf("%s\n", ret);
					return 1;
				}
				
				stdout.printf("%s\n", ret);
				return 0;
			case "umount":
				if (args.length == 2)
					return 0;
				if (args[2].length == 0)
					return 0;
				stdout.printf("%s\n", bus.u_mount(args[2]));
				return 0;
			case "getmount":
				if (args.length == 2) {
					stderr.printf(_("Error: You must provide a pkgid from which the mount point is resolved\n"));
					return 1;
				}
				
				ret = bus.mount_point_get(args[2]);
				if (ret == "!") {
					stderr.printf(_("Error: Package %s is not in database\n"), args[2]);
					return 1;
				}
				stdout.printf("%s\n", ret);
				return 0;
			case "register":
				string path;
				if (args.length == 2) {
					stderr.printf(_("Error: A path to the package that is to be registered needs to be provided\n"));
					return 1;
				}
				
				if (Path.is_absolute(args[2]))
					path = args[2];
				else
					path = Path.build_path(Environment.get_current_dir(), args[2], null);
				ret2 = bus.register_path(path, out ret);

				if (int.parse(ret) < 0) {
					if (int.parse(ret) == -1013)	/* Package already registered */
						stderr.printf(_("Warning: Package with pkgid %s is already registered at %s\n"), ret2, bus.path_from_id(ret2));
					else {
						/* TODO: print error */
						return 1;
					}
				}

				stdout.printf("%s\n", ret2);
				return 0;
			case "unregister":
				if (args.length == 2) {
					stderr.printf(_("Error: A path to the package that is to be unregistered needs to be provided\n"));
					return 1;
				}
				
				if (Path.is_absolute(args[2]))
					ret = bus.unregister_path(args[2]);
				else
					ret = bus.unregister_path(Path.build_path(Environment.get_current_dir(), args[2], null));
				if (int.parse(ret) < 0) {
					stderr.printf(_("Warning: package %s isn't registered\n"), args[2]);
					return 1;
				}

				return 0;
			case "id":
				if (args.length == 2) {
					stderr.printf(_("Error: A path to the package that pkgid is to be returned for needs to be provided\n"));
					return 1;
				}

				ret = bus.id_from_path(args[2]);
				if (ret == "!") {
					stderr.printf(_("Error: No package with path '%s' exists in the database\n"), args[2]);
					return 1;
				}

				stdout.printf("%s\n", ret);
				return 0;
			case "path":
				if (args.length == 2) {
					stderr.printf(_("Error: A pkgid to resolve path for needs to be provided\n"));
					return 1;
				}

				ret = bus.path_from_id(args[2]);
				if (ret == "!") {
					stderr.printf(_("Error: No package with the pkgid %s exists in the database\n"));
					return 1;
				}

				stdout.printf("%s\n", ret);
				return 0;
			case "list":
				string[] reta;

				reta = bus.package_list();
				for (int i = 0; i < reta.length/3; i++) {
					stdout.printf("'%s' '%s' '%s'\n", reta[i*3], reta[i*3+1], reta[i*3+2]);
				}

				return 0;
			case "ping":
				bus.ping();
				return 0;
			case "help":
				usage();
				return 0;
			default:
				stdout.printf(_("Error: Invalid option %s\n"), args[1]);
				usage();
				return 1;
		}
	} catch(Error e) {
		stderr.printf (_("Error: %s\n"), e.message);
		return 1;
	}
}
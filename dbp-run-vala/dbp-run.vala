//valid package names conform to /[-_\.a-zA-Z0-9]+/
[CCode(cname="GETTEXT_PACKAGE")]
extern const string GETTEXT_PACKAGE;

struct Config {
	bool gui_errors;
	bool log_output;
	bool chdir;
}

void usage() {
	stdout.printf(_("Usage: dbp-run [--gui-errors] [--log-output] [--chdir] <package id> <executable> [arg1] [arg2] ...\n"));
}

int main(string[] args) {
	string[] argv = {};
	bool parse_option;
	Config config = Config() {
		gui_errors = false,
		log_output = false,
		chdir = false
	};
	bus = null;
	
	Intl.setlocale(LocaleCategory.MESSAGES, "");
	Intl.textdomain(GETTEXT_PACKAGE); 
	Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8"); 
	Intl.bindtextdomain(GETTEXT_PACKAGE, "./po");
	DBP.Config.init();
	
	try {
		bus = Bus.get_proxy_sync(BusType.SYSTEM, DBP.DBus.DAEMON_PREFIX, DBP.DBus.DAEMON_OBJECT);
	} catch(Error e) {
		stderr.printf (_("Error: %s\n"), e.message);
		return 1;
	}
	
	parse_option = true;
	foreach(string s in args[1:args.length]) {
		if(s.length < 1 || s[0] != '-' || s[1] != '-')
			parse_option = false;
		
		if(parse_option) {
			switch(s) {
				case "--gui-errors":
					config.gui_errors = true;
					break;
				case "--log-output":
					config.log_output = true;
					break;
				case "--chdir":
					config.chdir = true;
					break;
				default:
					stderr.printf(_("Error: unknown option '%s'\n"), s);
					usage();
					return 1;
				case "--help":
					usage();
					return 0;
			}
		} else {
			argv += s;
		}
	}
	
	if(argv.length < 2) {
		usage();
		return 1;
	}
	
	try {
		Run.run(argv[0], argv[1], argv[2:argv.length], config.log_output, config.chdir);
	} catch(Error e) {
		stderr.printf(_("Error: %s\n"), e.message);
		return 1;
	}
	
	
	return 0;
}
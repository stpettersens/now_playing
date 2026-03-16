import std.conv;
import std.file;
import std.stdio;
import std.string;
import std.process;

string get_elevation() {
    auto result = executeShell("command -v doas");
    if (result.status != 0)
        return "sudo";

    return "doas";
}

bool have_playerctl() {
    string sudo = get_elevation();
    auto result = executeShell("command -v playerctl");
    if (result.status != 0) {
        // When playerctl is not found:
        // Prompt to install with typical package managers.
        writeln("Please install playerctl.\n");
        writefln("%s apt install playerctl", sudo);
        writefln("%s pacman -S playerctl", sudo);
        writefln("%s xbps-install -S playerctl\n", sudo);
    }

    return result.status == 0;
}

bool check_not_playing() {
    auto result = executeShell("playerctl metadata");
    return result.status != 0;
}

int print_playing(string[] players, string[] filters, int num_chars) {
    if (players.length == 0) {
        writeln("Error: No players configured.");
        return -1;
    }

    string cmd = format("playerctl --player=%s metadata --format \"{{ artist }} - {{ title }}\"",
    strip(players.join(",")));

    auto playing = executeShell(format("%s | cut -c1-%d", strip(cmd), num_chars));
    string track = strip(playing.output);

    // Apply filters to track.
    foreach (f; filters) {
       track = track.replace(f, "");
    }

    // Fix spacing.
    track = track.replace("-  ", "-");

    writeln(strip(track));
    return 0;
}

string[] read_players_cfg(string cfg_file) {
    string[] players = new string[0];
    if (!exists(cfg_file))
         return players;

    auto f = File(cfg_file);
    foreach (line; f.byLine()) {
        string l = strip(to!string(line));
        if (l.startsWith("#")) {
            // Ignore any comment lines in configuration file.
            continue;
        }

        players ~= l.toLower(); // Append player (priority order).
    }

    return players;
}

string[] read_filters_cfg(string cfg_file) {
    string[] filters = new string[0];
    if (!exists(cfg_file))
        return filters;

    auto f = File(cfg_file);
    foreach (line; f.byLine()) {
        string l = strip(to!string(line));
        if (l.startsWith('#')) {
            // Ignore any comment lines in configuration file.
            continue;
        }

        filters ~= l; // Append each filter.
    }

    return filters;
}

int display_error(string message) {
    writefln("Error: %s.\n", message);
    return -1;
}

int display_usage(string program, int num_chars) {
    writefln("Usage: %s [-h|--help][-t|--truncate n]", program);
    writeln("\nWhere n is number of characters to truncate to (n > 0).");
    writefln("If the -t switch is omitted, that is %d chars.", num_chars);
    return 0;
}

int main(string[] args) {
    immutable string program = "now_playing";
    int num_chars = 48; // Truncate now_playing track to 48 characters by default.

    if (args.length > 0) {
        int i = 0;
        foreach (a; args) {
            if (a == "-h" || a == "--help") {
                return display_usage(program, num_chars);
            }
            else if ((args.length == 3)
            && (a == "-t" || a == "--truncate")) {
                try {
                    num_chars = to!int(args[(i+1)]);
                    if (num_chars <= 0) {
                        return display_error("Truncation must be > 0 chars");
                    }
                }
                catch (Exception) {
                    return display_error("Truncation must be an integer");
                }
            }
            i++;
        }
    }

    if (!have_playerctl())
        return -1;

    if (check_not_playing()) {
        writeln("...");
        return 0;
    }

    immutable string cfg_dir = "/etc/now_playing";

    return print_playing
    (read_players_cfg(format("%s/players.cfg", cfg_dir)),
     read_filters_cfg(format("%s/filters.cfg", cfg_dir)),
     num_chars);
}

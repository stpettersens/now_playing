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
        writeln("Please install playerctl:\n");
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

int print_playing(string[] players) {
    if (players.length == 0) {
        writeln("Error: No players configured.");
        return -1;
    }

    writeln(players);

    auto playing = executeShell(format
    ("playerctl --player=%s metadata --format \"{{ artist }} - {{ title }}\" | cut -c1-42",
    strip(players.join(","))));

    writeln(playing.output);
    return 0;
}

string[] read_cfg(string cfg_file) {
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

int main() {
    if (!have_playerctl())
        return -1;

    if (check_not_playing()) {
        writeln("...");
        return 0;
    }

    return print_playing
    (read_cfg("/etc/now_playing.cfg"));
}

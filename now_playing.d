import std.conv;
import std.file;
import std.stdio;
import std.string;
import std.process;

import core.time;
import core.thread;
import core.sys.posix.unistd; // getlogin

void create_working_dir() {
    string dir = "/tmp/rb";
    auto login = getlogin();
    string user = fromStringz(login).idup;
    if (!exists(dir)) {
        executeShell(format("sudo -u %s mkdir -p %s", user, dir));
    }
}

void kill_get_song_loop(string pid_file) {
    if (exists(pid_file)) {
        auto f = File(pid_file, "r");
        string pid = strip(f.readln());
        executeShell(format("kill %s", pid));
        remove(pid_file);
    }
}

void print_song(string playing_file) {
    if (exists(playing_file)) {
        auto f = File(playing_file, "r");
        string song = strip(f.readln());
        writeln(song);
        return;
    }

    writeln("...");
}

void spawn_get_song_loop() {
    string pid_file = "/tmp/rb/pid";
    string playing_file = "/tmp/rb/playing";
    bool rb_running = false;

    auto processes = executeShell("pgrep rhythmbox | xargs printf '%d,'");
    string[] pids = chop(strip(processes.output)).split(",");
    foreach (pid; pids) {
        uint p = to!uint(pid);
        if (p != 0) rb_running = true;
        break;
    }

    if (rb_running && !exists(pid_file)) {
        auto pid = spawnProcess("rb_get_song");
        auto fo = File(pid_file, "w");
        fo.write(pid.processID.to!string);
        fo.flush();
        Thread.sleep(5.seconds);
    }
    else if (!rb_running) {
        if (exists(playing_file)) {
            remove(playing_file);
        }

        kill_get_song_loop(pid_file);
    }

    print_song(playing_file);
}

int main() {
    create_working_dir();
    spawn_get_song_loop();
    return 0;
}

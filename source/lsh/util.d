module lsh.util;

import core.stdc.stdlib : getenv;
import std.algorithm : startsWith;
import std.format : format;
import std.string : cmp, fromStringz;

string getcwd()
{
    import std.file;
    auto cwd = std.file.getcwd;
    return tildeAbbr(cwd);
}

string tildeAbbr(string path)
{
    auto home = getHomeDir();
    if (cmp(path, home) == 0)
        return "~";
    else if (path.startsWith(home))
        return format("~%s", path[home.length .. $]);
    return path;
}

string getHomeDir()
{
    import core.sys.posix.unistd : getuid, sysconf, _SC_GETPW_R_SIZE_MAX;
    import core.sys.posix.pwd : getpwuid_r, passwd;

    auto home = getenv("HOME").fromStringz;
    if (home.length != 0)
        return cast(immutable) home;
    auto amt = sysconf(_SC_GETPW_R_SIZE_MAX);
    if (amt == -1)
        amt = 512;
    ubyte[] buffer;
    buffer.reserve(amt);

    passwd _passwd;
    passwd *result;
    auto _ = getpwuid_r(getuid(), &_passwd, cast(char*) buffer.ptr,
                        amt, &result);
    if (result !is null)
    {
        return cast(immutable) fromStringz(_passwd.pw_dir);
    }
    return "";
}

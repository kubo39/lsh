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
    auto home = getenv("HOME").fromStringz;
    if (cmp(path, home) == 0)
        return "~";
    else if (path.startsWith(home))
        return format("~%s", path[home.length .. $]);
    return path;
}

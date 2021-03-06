module lsh.builtin;

import lsh.builtin.echo;
import lsh.shell : Shell;
import lsh.util : getHomeDir;
import std.file : chdir, FileException;
import std.stdio;

alias BuiltinFunction = int function(string[], Shell);

int builtinCd(string[] args, Shell shell)
{
    auto targetDir = args.length < 2 ? getHomeDir : args[1];
    try
    {
        chdir(targetDir);
    }
    catch (FileException _)
    {
        return 1;
    }
    return 0;
}

int builtinHelp(string[] args, Shell shell)
{
    stdout.writeln(`
This is D port of Stephen Brennan's LSH.
Type program names and arguments, and hit enter.
Use the man command for information on other programs.
`);
    return 0;
}

int builtinExit(string[] args, Shell shell)
{
    auto previousStatus = shell.previousStatus;
    shell.exit(previousStatus);
    assert(0);
}

int builtinIsatty(string[] args, Shell _)
{
    import core.sys.posix.unistd : isatty;
    import std.conv : ConvException, parse;

    if (args.length > 1)
    {
        try
        {
            auto fd = parse!int(args[0]);
            return isatty(fd);
        }
        catch (ConvException _)
        {
            return 1;
        }
    }
    else
    {
        return 1;
    }
}

class Builtins
{
    // Builtins should A-Z order.
    BuiltinFunction[string] builtinMap;

    this()
    {
        this.builtinMap = [
            "cd": &builtinCd,
            "echo": &builtinEcho,
            "exit": &builtinExit,
            "help": &builtinHelp,
            "isatty": &builtinIsatty,
            ];
    }

    string[] keys()
    {
        return this.builtinMap.keys();
    }

    BuiltinFunction get(string builtin)
    {
        return this.builtinMap[builtin];
    }
}

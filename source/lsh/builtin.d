module lsh.builtin;

import std.file : chdir;
import std.stdio;

alias BuiltinFunction = int function(string[]);

int builtinCd(string[] args)
{
    if (args.length < 2)
    {
        stderr.writeln(`lsh: expected argument to "cd"`);
    }
    else
    {
        chdir(args[1]);
    }
    return 1;
}

int builtinHelp(string[] args)
{
    stdout.writeln(`
This is D port of Stephen Brennan's LSH.
Type program names and arguments, and hit enter.
Use the man command for information on other programs.
`);
    return 1;
}

int builtinExit(string[] args)
{
    return 0;
}

class Builtins
{
    // Builtins should A-Z order.
    BuiltinFunction[string] builtinMap;

    this()
    {
        this.builtinMap = [
            "cd": &builtinCd,
            "exit": &builtinExit,
            "help": &builtinHelp,
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

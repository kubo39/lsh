module lsh.builtin;

import lsh.builtin.echo;
import lsh.shell : Shell;
import std.file : chdir, FileException;
import std.stdio;

alias BuiltinFunction = int function(string[], Shell);

int builtinCd(string[] args, Shell shell)
{
    if (args.length < 2)
    {
        stderr.writeln(`lsh: expected argument to "cd"`);
        return 1;
    }
    else
    {
        try
        {
            chdir(args[1]);
        }
        catch (FileException _)
        {
            return 1;
        }
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

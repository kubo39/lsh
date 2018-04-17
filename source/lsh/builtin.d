module lsh.builtin;

import lsh.shell : Shell;
import std.algorithm : startsWith;
import std.conv : to;
import std.file : chdir;
import std.stdio;
import std.typecons : BitFlags;

alias BuiltinFunction = int function(string[], Shell);

enum EchoFlags
{
    ESCAPE = 1,
    NO_NEWLINE = 1 << 1,
}

alias Flags = BitFlags!EchoFlags;

int builtinCd(string[] args, Shell shell)
{
    if (args.length < 2)
    {
        stderr.writeln(`lsh: expected argument to "cd"`);
        return 1;
    }
    else
    {
        chdir(args[1]);
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

int builtinEcho(string[] args, Shell shell)
{
    import std.array : appender;
    auto data = appender!(string[]);
    Flags flags;
    foreach (arg; args)
    {
        if (arg.startsWith('-'))
        {
            bool isOption = true;
            Flags shortFlags;

            foreach (argOpt; arg[1..$])
            {
                if (argOpt == 'e')
                    shortFlags |= EchoFlags.ESCAPE;
                else if (argOpt == 'n')
                    shortFlags |= EchoFlags.NO_NEWLINE;
                else
                {
                    isOption = false;
                    break;
                }
            }
            if (isOption)
                flags |= shortFlags;
            else
                data.put(arg);
        }
        else
        {
            data.put(arg);
        }
    }

    auto buffer = stdout.lockingTextWriter();
    bool first = true;
    foreach (arg; data.data[1..$])
    {
        if (flags && EchoFlags.ESCAPE)
        {
            bool check = false;
            foreach (c; arg)
            {
                switch (c)
                {
                case '\\':
                    if (check)
                    {
                        buffer.put(c);
                        check = false;
                    }
                    else
                        check = true;
                    break;
                case 'a':
                    if (check)
                    {
                        buffer.put(7.to!char); // bell.
                        check = false;
                        break;
                    }
                    goto default;
                case 'b':
                    if (check)
                    {
                        buffer.put(8.to!char); // backspace.
                        check = false;
                        break;
                    }
                    goto default;
                case 'c':
                    if (check)
                    {
                        stdout.flush();
                        return 0;
                    }
                    goto default;
                case 'e':
                    if (check)
                    {
                        buffer.put(27.to!char); // escape.
                        check = false;
                        break;
                    }
                    goto default;
                case 'f':
                    if (check)
                    {
                        buffer.put(12.to!char); // form feed.
                        check = false;
                        break;
                    }
                    goto default;
                case 'n':
                    if (check)
                    {
                        buffer.put('\n'); // newline.
                        check = false;
                        break;
                    }
                    goto default;
                case 'r':
                    if (check)
                    {
                        buffer.put('\r');
                        check = false;
                        break;
                    }
                    goto default;
                case 't':
                    if (check)
                    {
                        buffer.put('\t');
                        check = false;
                        break;
                    }
                    goto default;
                case 'v':
                    if (check)
                    {
                        buffer.put(11.to!char); // vertival tab.
                        check = false;
                        break;
                    }
                    goto default;
                default:
                    if (check)
                        buffer.put(['\\', c]);
                    else
                        buffer.put(c);
                    break;
                }
            }
        }
        else
            buffer.put(arg);
    }
    if (!(flags && EchoFlags.NO_NEWLINE))
        buffer.put("\n");
    stdout.flush();
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

module lsh.readline.terminal;

import core.sys.posix.termios;
import core.sys.posix.unistd : isatty;
import std.stdio : stdin;

class Terminal
{
    termios origTermios;
    bool rawMode;

    this()
    {
        this.rawMode = false;
    }

    ~this()
    {
        disableRawMode();
    }

    bool enableRawMode()
    {
        termios raw;
        if (isatty(stdin.fileno()) == 0)
            return false;
        if (tcgetattr(stdin.fileno(), &this.origTermios) == -1)
            return false;
        raw = this.origTermios;
        raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
        raw.c_oflag &= ~OPOST;
        raw.c_cflag |= CS8;
        raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
        raw.c_cc[VMIN] = 1;
        raw.c_cc[VTIME] = 0;
        if (tcsetattr(stdin.fileno(), TCSADRAIN, &raw) < 0)
            return false;
        rawMode = true;
        return true;
    }

    void disableRawMode()
    {
        if (rawMode && tcsetattr(stdin.fileno(), TCSAFLUSH, &this.origTermios) != -1)
            rawMode = false;
    }
}

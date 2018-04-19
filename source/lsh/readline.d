module lsh.readline;

import core.stdc.stdio : getchar;
import core.stdc.string : memmove;
import core.sys.posix.sys.ioctl;
import core.sys.posix.termios;
import core.sys.posix.unistd : isatty;
import std.array;
import std.format : format;
import std.stdio; // write

enum KEY_ACTION
{
    KEY_NULL = 0,
    CTRL_A = 1,
    CTRL_B = 2,
    CTRL_C = 3,
    CTRL_D = 4,
    CTRL_E = 5,
    CTRL_F = 6,
    CTRL_H = 8,
    TAB    = 9,
    CTRL_K = 11,
    CTRL_L = 12,
    ENTER  = 13,
    CTRL_N = 14,
    CTRL_P = 16,
    CTRL_T = 20,
    CTRL_U = 21,
    CTRL_W = 23,
    ESC     = 27,
    BACKSPACE =  127,
}

termios origTermios;
bool rawMode = false;

bool enableRawMode()
{
    termios raw;
    if (isatty(stdin.fileno()) == 0)
        return false;
    if (tcgetattr(stdin.fileno(), &origTermios) == -1)
        return false;
    raw = origTermios;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= (CS8);
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
    if (rawMode && tcsetattr(stdin.fileno(), TCSAFLUSH, &origTermios) != -1)
        rawMode = false;
}

int[2] getWindowSize()
{
    auto size = winsize();
    if (ioctl(stdout.fileno(), TIOCGWINSZ, &size) == -1 || size.ws_col == 0)
    {
        return [80, 24];
    }
    else
    {
        return [size.ws_col, size.ws_row];
    }
}

int getColumns(int infd, int outfd)
{
    return getWindowSize()[0];
}

class State
{
    LineBuffer line;
    string prompt;
    size_t oldpos;
    size_t len;
    size_t buflen;
    int cols;
    size_t maxrows;

    this(string prompt)
    {
        this.line = new LineBuffer();
        this.prompt = prompt;
        this.oldpos = 0;
        this.len = 0;
        this.buflen = 0;
        this.cols = getColumns(stdin.fileno(), stdout.fileno());
        this.maxrows = 0;
    }
}

string removeCodes(string input)
{
    import std.algorithm : canFind;
    if (input.canFind("\x1B"))
    {
        auto clean = appender!string();
        enum AnsiState
        {
            Norm,
            Esc,
            Csi,
            Osc,
        }
        AnsiState s = AnsiState.Norm;
        foreach (c; input)
        {
            final switch (s)
            {
            case AnsiState.Norm:
                if (c == '\x1B')
                {
                    s = AnsiState.Esc;
                }
                else
                {
                    clean.put(c);
                }
                break;
            case AnsiState.Esc:
                switch (c)
                {
                case '[':
                    s = AnsiState.Csi;
                    break;
                case ']':
                    s = AnsiState.Osc;
                    break;
                default:
                    s = AnsiState.Norm;
                    break;
                }
                break;
            case AnsiState.Csi:
                switch (c)
                {
                case 'A': .. case 'Z':
                case 'a': .. case 'z':
                    s = AnsiState.Norm;
                    break;
                default:
                    break;
                }
                break;
            case AnsiState.Osc:
                if (c == '\x07')
                    s = AnsiState.Norm;
                break;
            }
        }
        return clean.data;
    }
    else
    {
        return input;
    }
}

size_t width(string input)
{
    import std.range : walkLength;
    return removeCodes(input).walkLength;
}

void refreshLine(State state)
{
    auto plen = width(state.prompt);
    auto len = state.len;
    auto pos = state.line.pos;

    auto ab = appender!string();

    // clear old rows and line.
    ab.put("\r");
    // display the prompt.
    ab.put(state.prompt);
    // and buffer.
    ab.put(state.line.buffer);
    // Erase to right.
    ab.put("\x1b[0K");
    // move cursor to original position.
    ab.put(format("\r\x1b[%dC", pos+plen));

    // write and flush.
    write(ab.data);
    stdout.flush();
}

class LineBuffer
{
    char[] buffer;
    size_t pos;

    this()
    {
        this.buffer = [];
        this.buffer.reserve(80);
        this.pos = 0;
    }

    void put(char c)
    {
        this.buffer ~= c;
        this.pos++;
    }

    void clear()
    {
        this.buffer = [];
        this.pos = 0;
    }
}

bool editInsert(State state, char c)
{
    if (state.len < 1023)
    {
        if (state.len == state.line.pos)
        {
            state.line.put(c);
            state.len++;
            refreshLine(state);
        }
        else
        {
            state.line.buffer.insertInPlace(state.line.pos, [c]);
            state.line.pos++;
            state.len++;
            refreshLine(state);
        }
    }
    return true;
}

void editBackspace(State state)
{
    if (state.line.pos > 0 && state.len > 0)
    {
        state.line.pos--;
        state.len--;
        state.line.buffer = state.line.buffer[0 .. state.len];
        refreshLine(state);
    }
}

void moveLeft(State state)
{
    if (state.line.pos > 0)
    {
        state.line.pos--;
        refreshLine(state);
    }
}

void moveRight(State state)
{
    if (state.line.pos != state.len)
    {
        state.line.pos++;
        refreshLine(state);
    }
}

char[] readlineEdit(string prompt)
{
    auto state = new State(prompt);
    write(prompt);

    while (true)
    {
        auto c = cast(char) getchar();
        switch (c)
        {
        case KEY_ACTION.ENTER:
            return state.line.buffer;
        case KEY_ACTION.CTRL_C:
            return ['^', 'C'];
        case KEY_ACTION.BACKSPACE:
        case KEY_ACTION.CTRL_H:
            editBackspace(state);
            break;
        case KEY_ACTION.CTRL_D:
        case KEY_ACTION.CTRL_T:
            return null;
        case KEY_ACTION.CTRL_B:
            moveLeft(state);
            break;
        case KEY_ACTION.CTRL_F:
            moveRight(state);
            break;
        case KEY_ACTION.CTRL_P:
        case KEY_ACTION.CTRL_N:
        case KEY_ACTION.ESC:
            return null;
        default:
            editInsert(state, c);
            break;
        case KEY_ACTION.CTRL_U:
            state.line.clear();
            refreshLine(state);
            break;
        case KEY_ACTION.CTRL_K:
        case KEY_ACTION.CTRL_A:
        case KEY_ACTION.CTRL_E:
        case KEY_ACTION.CTRL_L:
        case KEY_ACTION.CTRL_W:
            return null;
        }
    }
    assert(false);
}

string readlineRaw(string prompt)
{
    if (!enableRawMode())
        return null;
    auto s = cast(immutable) readlineEdit(prompt);
    disableRawMode();
    writeln();
    return s;
}

string readline(string prompt)
{
    return readlineRaw(prompt);
}

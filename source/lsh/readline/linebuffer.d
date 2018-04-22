module lsh.readline.linebuffer;

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

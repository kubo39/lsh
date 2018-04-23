module lsh.readline.linebuffer;

class LineBuffer
{
    char[] buffer;
    size_t pos;  // Current cursor position.

    this(size_t cap)
    {
        this.buffer = [];
        this.buffer.reserve(cap);
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

    bool moveHome()
    {
        if (this.pos > 0)
        {
            this.pos = 0;
            return true;
        }
        else
        {
            return false;
        }
    }

    bool moveEnd()
    {
        if (this.pos == this.buffer.length)
        {
            return false;
        }
        else
        {
            this.pos = this.buffer.length;
            return true;
        }
    }
}

/**
Write a shell in C.  https://brennan.io/2015/01/16/write-a-shell-in-c/
*/
import lsh.shell : Shell;

void main(string[] args)
{
    auto lsh = new Shell;

    foreach (arg; args[1..$])
    {
        switch (arg)
        {
        case "-v", "--version":
            lsh.displayVersion();
        default:
            // do nothing.
        }
    }

    lsh.setPrompt(() => " > ");
    lsh.loop();
}

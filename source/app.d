/**
Write a shell in C.  https://brennan.io/2015/01/16/write-a-shell-in-c/
*/
import lsh.shell : Shell;

void main()
{
    auto lsh = new Shell;
    lsh.loop();
}

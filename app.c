#include <stdio.h>
#include <locale.h>

void print(char* str, ...); // пототип функции из файла на ассемблере

int main(void) {
    setlocale(LC_ALL, "");
    char* str = "привет!\nIt dec %d\nIt hex %x \n It octal %o \nIt binary %b\n%d\n%x\n%o\n";
    int k1 = -10;
    int k2 = -80;
    int k3 = 87;
    int k4 = 55;
    int k5 = 98;
    int k6 = 214;
    int k7 = 21;

    print(str, k1, k2, k3, k4, k5, k6, k7);

    print("like a rocket%c man %o\n", 'm', k3);

    char* mamka = "punky hoi! Punky hoi!";

    print("Hei\nIt is %s! He%c hoi %d", mamka, ';', k4);
   /* print("%d\n", i2);
    i2 = 40;
    print("%d\n", i2);
    i2 = 50;
    print("%d\n", i2);
    return 0;*/

}

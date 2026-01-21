int main() {
  int a = 1, b = 1, c;
  while (1) {
    c = a + b;
    a = b;
    b = c;
  }
}
import os
import sys

filepath = sys.argv[1]

filename, ext = os.path.splitext(filepath)

match ext:
    case ".s":
        os.system(f"riscv32-unknown-elf-as {filepath} -o {filename}.o -march=rv32i")
    case ".c":
        os.system(
            f"riscv32-unknown-elf-gcc {filepath} -o {filename}.o -c -march=rv32i -mabi=ilp32"
        )

os.system(f"riscv32-unknown-elf-ld {filename}.o -o {filename}.elf")
os.system(f"riscv32-unknown-elf-objcopy -O binary {filename}.elf {filename}.bin")
os.system(f"xxd -e -p -c 1 {filename}.bin>{filename}.txt")

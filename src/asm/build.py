import os
import sys

filepath = sys.argv[1]

filename, ext = os.path.splitext(filepath)

match ext:
    case ".s":
        os.system(f"riscv64-unknown-elf-as {filepath} -o {filename}.o -march=rv32g")
    case ".c":
        os.system(
            f"riscv64-unknown-elf-gcc {filepath} -o {filename}.o -c -march=rv32g -mabi=ilp32"
        )

os.system(
    f"riscv64-unknown-elf-ld {filename}.o -o {filename}.elf -T linker.ld -m elf32lriscv"
)
os.system(f"riscv64-unknown-elf-objcopy -O binary {filename}.elf {filename}.bin")

with open(f"{filename}.bin", mode="rb") as file:
    data = file.read()
with open(f"{filename}.coe", mode="w") as file:
    file.write("memory_initialization_radix = 16;\n")
    file.write("memory_initialization_vector =\n")
    data = data.hex()
    print(data)
    data = [data[i : i + 2] for i in range(0, len(data), 2)]
    for i in range(8, len(data) + 8, 8):
        for _ in range(2):
            file.write("".join(data[i - 4 : i][::-1]))
            i -= 4
        file.write(",\n")

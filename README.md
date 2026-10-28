# binconv

A small Bash command-line tool that converts numbers between **decimal**, **binary**, and **hexadecimal**, and shows text as ASCII bytes.

I built it while relearning number systems for security work. The decimal-to-binary conversion is written out by hand ("biggest place first") instead of relying on a built-in, so the script doubles as a readable example of how the conversion works.

## Usage

```bash
./binconv.sh 42            # decimal input
./binconv.sh 0b101010      # binary input
./binconv.sh 0x2A          # hex input
./binconv.sh --text yeah   # show each character as a byte
./binconv.sh --help
```

## Examples

```
$ ./binconv.sh 340
Decimal: 340
Binary:  0000 0001 0101 0100   (16 bits)
Hex:     0x0154
Places:  256 + 64 + 16 + 4
```

```
$ ./binconv.sh 0xC0A80101
Decimal: 3232235777
Binary:  1100 0000 1010 1000 0000 0001 0000 0001   (32 bits)
Hex:     0xC0A80101
Places:  2147483648 + 1073741824 + 8388608 + 2097152 + 524288 + 256 + 1
```

That second one is the IP address `192.168.1.1`: each group of 8 bits is one part of the address.

```
$ ./binconv.sh --text Hi
Char   Dec  Binary    Hex
H      72   01001000  0x48
i      105  01101001  0x69
```

## Features

- Accepts decimal, `0b` binary, and `0x` hex input
- Handles 0 to 4,294,967,295 (32 bits); output width grows to fit (8, 16, or 32 bits)
- Shows which place values add up to the number
- `--text` mode prints ASCII codes in decimal, binary, and hex
- Clear error messages for invalid or too-large input
- Runs on macOS's built-in Bash 3.2 and on Linux

## Install

```bash
git clone https://github.com/Robb-89/bincov.git
cd bincov
chmod +x binconv.sh
./binconv.sh 42
```

To run it as `binconv` from anywhere, copy it into a folder on your `PATH`:

```bash
cp binconv.sh /usr/local/bin/binconv
```

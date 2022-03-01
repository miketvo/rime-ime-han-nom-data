import sys


def print_help():
    print(
        '\n'
        'Syntax: py combine.py <encoding> <path/to/file_1> <path/to/file_2> .. <path/to/file_n> <path/to/output/file>\n'
        'At least 2 input files needed.\n'
    )


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print_help()
    else:
        encoding = sys.argv[1]
        outpath = sys.argv[-1]
        inpaths = sys.argv[2:-1]

        all_lines = []

        for inpath in inpaths:
            inf = open(inpath, 'r', encoding=encoding)
            for line in inf:
                all_lines.append(line)
            inf.close()

        outf = open(outpath, 'w', encoding=encoding)
        outf.writelines(all_lines)
        outf.close()

import vnrhymes as vnr


if __name__ == '__main__':
    print('Generating Vietnamese rhymes... ', end='')
    rhymes = vnr.generate()
    print(f'{len(rhymes)} generated. [DONE]')

    file = open('../compiled/schema_gen.out.txt', 'w', encoding='utf-8')
    for rhyme in rhymes:
        file.write(f"    - 'xform {rhyme.base}{rhyme.modifier} {rhyme.result}'\n")
    file.close()

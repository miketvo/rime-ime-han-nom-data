import vntelex as telex


if __name__ == '__main__':
    data = []
    file = open('../raw-data/standard-list.csv', 'r', encoding='utf-8')
    for line in file:
        split = line.split(',')
        data.append({
            'hn': split[0],
            'telex': split[1],
            'freq': int(split[2]),
        })
    file.close()

    for i in range(len(data)):
        entry = ''
        words = data[i]['telex'].split(' ')
        for j in range(len(words)):
            if words[j] == '':
                continue
            parts = telex.decompose(words[j].lower())
            entry += parts['onset'] + parts['rhyme'] + parts['tone']
            if j < len(words) - 1:
                entry += ' '
        data[i]['telex'] = entry

    file = open('../raw-data/standard-list.csv', 'w', encoding='utf-8')
    for entry in data:
        file.write(f'{entry["hn"]},{entry["telex"]},{entry["freq"]}\n')
    file.close()

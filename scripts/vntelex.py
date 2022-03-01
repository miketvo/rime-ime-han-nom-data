import re


ONSETS = {
    'b': 'b',
    'd': 'd',
    'h': 'h',
    'l': 'l',
    'm': 'm',
    'n': 'n',
    'p': 'p',
    'r': 'r',
    's': 's',
    't': 't',
    'v': 'v',
    'x': 'x',
    'đ': 'dd',
    'tr': 'tr',
    'th': 'th',
    'ch': 'ch',
    'ph': 'ph',
    'nh': 'nh',
    'kh': 'kh',
    'gi': 'gi',
    'qu': 'qu',
    'ngh': 'ngh',
    'ng': 'ng',
    'gh': 'gh',
    'g': 'g',
    'k': 'k',
    'c': 'c',
}
RHYMES = {
    'a': 'a',
    'ă': 'aw',
    'â': 'aa',
    'e': 'e',
    'ê': 'ee',
    'i': 'i',
    'o': 'o',
    'ô': 'oo',
    'ơ': 'ow',
    'u': 'u',
    'ư': 'uw',
    'y': 'y',
    'iê': 'iee',
    'oa': 'oa',
    'oă': 'oaw',
    'oe': 'oe',
    'uâ': 'uaa',
    'uê': 'uee',
    'uô': 'uoo',
    'uơ': 'uow',
    'ươ': 'uwow',
    'uy': 'uy',
    'uyê': 'uyee',
    'yê': 'yee',
    'ia': 'ia',
    'ua': 'ua',
    'ưa': 'uwa',
    'uya': 'uya',
    'ai': 'ai',
    'oi': 'oi',
    'ôi': 'ooi',
    'ơi': 'owi',
    'ui': 'ui',
    'ưi': 'uwi',
    'oai': 'oai',
    'uôi': 'uooi',
    'ươi': 'uwowi',
    'ao': 'ao',
    'eo': 'eo',
    'oao': 'oao',
    'oeo': 'oeo',
    'au': 'au',
    'âu': 'aau',
    'êu': 'eeu',
    'uêu': 'ueeu',
    'iu': 'iu',
    'ưu': 'uwu',
    'iêu': 'ieeu',
    'uyu': 'uyu',
    'ươu': 'uwowu',
    'yêu': 'yeeu',
    'ay': 'ay',
    'ây': 'aay',
    'oay': 'oay',
    'uây': 'ɮʒʊ',
    'am': 'am',
    'ăm': 'awm',
    'âm': 'aam',
    'em': 'em',
    'êm': 'eem',
    'im': 'im',
    'om': 'om',
    'ôm': 'oom',
    'ơm': 'owm',
    'um': 'um',
    'ưm': 'uwm',
    'iêm': 'ieem',
    'oam': 'oam',
    'oăm': 'oawm',
    'oem': 'oem',
    'uôm': 'uoom',
    'ươm': 'uwowm',
    'yêm': 'yeem',
    'an': 'an',
    'ăn': 'awn',
    'ân': 'aan',
    'en': 'en',
    'ên': 'een',
    'in': 'in',
    'on': 'on',
    'ôn': 'oon',
    'ơn': 'own',
    'un': 'un',
    'ưn': 'uwn',
    'iên': 'ieen',
    'oan': 'oan',
    'oăn': 'oawn',
    'oen': 'oen',
    'uân': 'uaan',
    'uôn': 'uoon',
    'uyn': 'uyn',
    'ươn': 'uwown',
    'uyên': 'uyeen',
    'yên': 'yeen',
    'ang': 'ang',
    'ăng': 'awng',
    'âng': 'aang',
    'eng': 'eng',
    'ong': 'ong',
    'ông': 'oong',
    'ung': 'ung',
    'ưng': 'uwng',
    'iêng': 'ieeng',
    'oang': 'oang',
    'oăng': 'oawng',
    'uăng': 'uawng',
    'uâng': 'uaang',
    'uông': 'uoong',
    'ương': 'uwowng',
    'yêng': 'yeeng',
    'anh': 'anh',
    'ênh': 'eenh',
    'inh': 'inh',
    'iênh': 'ieenh',
    'oanh': 'oanh',
    'uênh': 'ueenh',
    'uynh': 'uynh',
    'ynh': 'ynh',
    'ach': 'ach',
    'êch': 'eech',
    'ich': 'ich',
    'oach': 'oach',
    'uêch': 'ueech',
    'uych': 'uych',
    'ac': 'ac',
    'ăc': 'awc',
    'âc': 'aac',
    'ec': 'ec',
    'oc': 'oc',
    'ôc': 'ooc',
    'uc': 'uc',
    'ưc': 'uwc',
    'iêc': 'ieec',
    'oac': 'oac',
    'oăc': 'oawc',
    'uôc': 'uooc',
    'ươc': 'uwowc',
    'at': 'at',
    'ăt': 'awt',
    'ât': 'aat',
    'et': 'et',
    'êt': 'eet',
    'it': 'it',
    'ot': 'ot',
    'ôt': 'oot',
    'ơt': 'owt',
    'ơc': 'owc',
    'ut': 'ut',
    'ưt': 'uwt',
    'iêt': 'ieet',
    'oat': 'oat',
    'oăt': 'oawt',
    'oet': 'oet',
    'uât': 'uaat',
    'uôt': 'uoot',
    'uyt': 'uyt',
    'ươt': 'uwowt',
    'uyêt': 'uyeet',
    'yêt': 'yeet',
    'ap': 'ap',
    'ăp': 'awp',
    'âp': 'aap',
    'ep': 'ep',
    'êp': 'eep',
    'ip': 'ip',
    'op': 'op',
    'ôp': 'oop',
    'ơp': 'owp',
    'up': 'up',
    'iêp': 'ieep',
    'oap': 'oap',
    'uôp': 'uoop',
    'uyp': 'uyp',
    'ươp': 'uwowp',
}
TONES = {
    'flat': list('aeiouăâêôơưy'),
    'rise': list('áéíóúắấếốớứý'),
    'fall': list('àèìòùằầềồờừỳ'),
    'inquire': list('ảẻỉỏủẳẩểổởửỷ'),
    'break': list('ãẽĩõũẵẫễỗỡữỹ'),
    'heavy': list('ạẹịọụặậệộợựỵ'),
}


def decompose(s):
    onset_pattern = '^(b|d|h|l|m|n|p|r|s|t|v|x|đ|tr|th|ch|ph|nh|kh|gi|qu|ngh|ng|gh|g|k|c)(?=[aeiouăâêôơưyáéíóúắấếốớứýàèìòùằầềồờừỳảẻỉỏủẳẩểổởửỷãẽĩõũẵẫễỗỡữỹạẹịọụặậệộợựỵ])'
    result_array = re.split(onset_pattern, s)
    if len(result_array) != 1:
        result_array = result_array[1:]
    try:
        rhyme_pos = 1
        if len(result_array) == 1:
            rhyme_pos = 0
            onset = ''
        else:
            onset = ONSETS[result_array[0]]
        tone = get_tone(s)

        result_array[rhyme_pos] = result_array[rhyme_pos].lower()
        toneless_rhyme = ''
        for i in range(len(result_array[rhyme_pos])):
            if result_array[rhyme_pos][i].lower() in TONES['flat']:
                toneless_rhyme += TONES['flat'][TONES['flat'].index(result_array[rhyme_pos][i])]
            elif result_array[rhyme_pos][i].lower() in TONES['rise']:
                toneless_rhyme += TONES['flat'][TONES['rise'].index(result_array[rhyme_pos][i])]
            elif result_array[rhyme_pos][i].lower() in TONES['fall']:
                toneless_rhyme += TONES['flat'][TONES['fall'].index(result_array[rhyme_pos][i])]
            elif result_array[rhyme_pos][i].lower() in TONES['inquire']:
                toneless_rhyme += TONES['flat'][TONES['inquire'].index(result_array[rhyme_pos][i])]
            elif result_array[rhyme_pos][i].lower() in TONES['break']:
                toneless_rhyme += TONES['flat'][TONES['break'].index(result_array[rhyme_pos][i])]
            elif result_array[rhyme_pos][i].lower() in TONES['heavy']:
                toneless_rhyme += TONES['flat'][TONES['heavy'].index(result_array[rhyme_pos][i])]
            else:
                toneless_rhyme += result_array[rhyme_pos][i].lower()

        return {
            'onset': onset,
            'rhyme': RHYMES[toneless_rhyme],
            'tone': tone,
        }
    except IndexError:
        return None


def get_tone(s):
    for char in s:
        if char in TONES['rise']:
            return 's'
        if char in TONES['fall']:
            return 'f'
        if char in TONES['inquire']:
            return 'r'
        if char in TONES['break']:
            return 'x'
        if char in TONES['heavy']:
            return 'j'
    return 'z'

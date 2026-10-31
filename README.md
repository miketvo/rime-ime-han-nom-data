# rime-ime-han-nom-data

Han Nom Telex schema and dictionary data for Rime (https://rime.im).

An input method for Vietnamese Han Nom.

Improvements based on [Weasel Hannom](https://chinese.com.vn/weasel-hannom.html) by Keepout2010 <Keepout2010@163.com>, with added data by scraping [Wiktionary](https://www.wiktionary.org) and a more accurate Telex schema.

## Features

- The full unconfirmed Telex input remains available to dictionary and phrase lookup while the preedit shows Vietnamese syllable boundaries.
- Valid Telex converts to Vietnamese on Return, including mixed selected Han-Nom and unselected Vietnamese text.
- Upper-case Telex lookup is supported and case is preserved in the Vietnamese output.
- Tone-key placement variants, `dd`/`Đ`, half-width punctuation, and spacing around punctuation are handled.
- Lua modules provide live preedit preview, syllable segmentation, and Enter-key conversion.

## Installation

Use a Rime distribution with Lua support enabled. Copy `hannom-telex.schema.yaml`, `hannom-telex.dict.yaml`, and the `lua/` directory into the Rime user-data directory, keeping the `lua/` subdirectory, then add `hannom-telex` to `schema_list` in `default.custom.yaml` and redeploy.

```yaml
patch:
  schema_list:
    - schema: hannom-telex
```

The schema depends on Rime's `cangjie5` schema for reverse lookup.

## Status

The schema was developed with Squirrel on macOS. Key-by-key behavior and other Rime distributions have not been re-verified for this revision.

## Data sources

- [Chữ Nôm Standard](https://chunom.org/pages/standard/) (general list, including frequency data for common words)
- [Vietnamese Wiktionary](https://vi.wiktionary.org/wiki/) (syllable-oriented data)
- [HVDic](https://hvdic.thivien.net/rad-hv) (stroke-oriented data)
- [Han-Nom Revival Committee standard lookup](https://www.hannom-rcv.org/standard-nom/Lookup-CHNC.html)

The Lua syllable table is generated from the [7,184-syllable Vietnamese frequency list](https://gist.github.com/hieuthi/1f5d80fca871f3642f61f7e3de883f3a).

## Acknowledgements

The original schema and dictionary work is by Mike Vo (武祥明), building on Weasel Hannom by Keepout2010. The changes in this revision were produced with the **GPT-6 Luna** model.

## License

MIT. See [LICENSE](LICENSE).

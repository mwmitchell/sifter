module MarcHelpers
  
  module MapperMethods
    
    # pass in the input, which gets sent to
    # the current marc records #extact method (see the Record module below)
    def marc input, &block
      @current.extract input, &block
    end
    
    protected
    
    # "cleans" a value, or array of values
    # returned value/values are converted to strings
    def clean value
      value.is_a?(Array) ? value.map{|v| clean_value(v) } : clean_value(value)
    end
    
    def clean_value value
      value.to_s.strip.sub /[\W]+$/, ''
    end
    
  end
  
  # mix this guy into a MARC::Record object
  module Record
    
    SPLIT_REGEXP = /^(\d+)([a-z]{0,1})/
    
    # the input can be a string or array
    # if a string is passed in:
    #   a string is returned
    #   multiple fields can be specified by separating w/spaces: "245a 245b"
    # if an array is passed in:
    #   an array is returned
    #   multiple values are specified by separate items in array: ["245a", "245b"]
    # if a block is used, the final values are yielded
    # and the result of the yield is returned
    def extract input, &block
      if input.is_a?(Array)
        all = true
        marc_fields = input
      else
        all = false
        marc_fields = input.split(' ')
      end
      values = marc_fields.map do |marc_field|
        # split the marc field by digit (main field) and alpha char (sub-field)
        main,sub = marc_field.scan(SPLIT_REGEXP).first
        # if there is a sub... grab it
        # else grab just the main field value
        if sub
          self[main] ? self[main][sub] : nil
        else
          self[marc_field]
        end
      end
      result = all ? values.uniq.reject{|v|v.to_s.empty?} : values.first
      block_given? ? yield(result) : result
    end
    
    # http://woss.name/2005/09/09/isbn-validation-part-2
    def valid_isbn?(isbn, c_map = '0123456789X')
      sum = 0
      return unless isbn
      match = isbn[0..-2].to_s.scan(/\d/)
      match.each_with_index do |c,i|
        sum += c.to_i * (i+1)
      end
      isbn[-1] == c_map[sum % c_map.length]
    end
  
    # extracts valid isbns
    def isbn
      values = self.extract(['020a'])
      # go through each value
      values.select do |v| # "select" collects values only if the last line of this block is true
        # split on a space, grab the first
        isbn = v.to_s.split(' ').first
        # is it valid?
        valid_isbn?(isbn)
      end
    end
  
    # returns the mapped language value
    def languages
      values = [self['008'].value[35..37]]
      values += self.extract(['041a', '041d'])
      values.uniq!
      mapped = values.map{|code| FieldMaps::LANGUAGE[code] }
      mapped.reject{|v| v.to_s.empty? }
    end
    
    # http://www.itsmarc.com/crs/Bib0021.htm#Leader_06_Definition
    def format
      char_6 = self.leader[6...7]
      char_7 = self.leader[7...8]
      if char_6 == 'a' and %W(a c d m).include? char_7
        code = 'a'
      elsif %W(b s).include? char_7
        code = 'serials'
      else
        code = char_6
      end
      FieldMaps::FORMAT[code] || 'Unknown'
    end
    
    # downcased and stripped of funny chars
    def format_code
      format.to_s.downcase.gsub(/ _/, ' ').gsub(/ /, '_')
    end
    
    # http://www.loc.gov/marc/authority/ad001.html
    def control_code
      self['001'].value.gsub(" ","").gsub("/","")
    end
    
  end
  
  module FieldMaps

    FORMAT = {
      'v' => %(Video),
      'a' => %(Book),
      't' => %(Book),
      'm' => %(Computer File),
      'c' => %(Musical Score),
      'd' => %(Musical Score),
      'j' => %(Musical Recording),
      'i' => %(Non-musical Recording),
      'serials' => %(Serials)
    }

    LANGUAGE = {
      '???' => '',
      'aar' => %(Afar),
      'abk' => %(Abkhaz),
      'ace' => %(Achinese),
      'ach' => %(Acoli),
      'ada' => %(Adangme),
      'ady' => %(Adygei),
      'afa' => %(Afroasiatic (Other)),
      'afh' => %(Afrihili (Artificial language)),
      'afr' => %(Afrikaans),
      'ajm' => %(Aljamia),
      'aka' => %(Akan),
      'akk' => %(Akkadian),
      'alb' => %(Albanian),
      'ale' => %(Aleut),
      'alg' => %(Algonquian (Other)),
      'amh' => %(Amharic),
      'ang' => %(English, Old (ca. 450-1100)),
      'apa' => %(Apache languages),
      'ara' => %(Arabic),
      'arc' => %(Aramaic),
      'arg' => %(Aragonese Spanish),
      'arm' => %(Armenian),
      'arn' => %(Mapuche),
      'arp' => %(Arapaho),
      'art' => %(Artificial (Other)),
      'arw' => %(Arawak),
      'asm' => %(Assamese),
      'ast' => %(Bable),
      'ath' => %(Athapascan (Other)),
      'aus' => %(Australian languages),
      'ava' => %(Avaric),
      'ave' => %(Avestan),
      'awa' => %(Awadhi),
      'aym' => %(Aymara),
      'aze' => %(Azerbaijani),
      'bad' => %(Banda),
      'bai' => %(Bamileke languages),
      'bak' => %(Bashkir),
      'bal' => %(Baluchi),
      'bam' => %(Bambara),
      'ban' => %(Balinese),
      'baq' => %(Basque),
      'bas' => %(Basa),
      'bat' => %(Baltic (Other)),
      'bej' => %(Beja),
      'bel' => %(Belarusian),
      'bem' => %(Bemba),
      'ben' => %(Bengali),
      'ber' => %(Berber (Other)),
      'bho' => %(Bhojpuri),
      'bih' => %(Bihari),
      'bik' => %(Bikol),
      'bin' => %(Edo),
      'bis' => %(Bislama),
      'bla' => %(Siksika),
      'bnt' => %(Bantu (Other)),
      'bos' => %(Bosnian),
      'bra' => %(Braj),
      'bre' => %(Breton),
      'btk' => %(Batak),
      'bua' => %(Buriat),
      'bug' => %(Bugis),
      'bul' => %(Bulgarian),
      'bur' => %(Burmese),
      'cad' => %(Caddo),
      'cai' => %(Central American Indian (Other)),
      'cam' => %(Khmer),
      'car' => %(Carib),
      'cat' => %(Catalan),
      'cau' => %(Caucasian (Other)),
      'ceb' => %(Cebuano),
      'cel' => %(Celtic (Other)),
      'cha' => %(Chamorro),
      'chb' => %(Chibcha),
      'che' => %(Chechen),
      'chg' => %(Chagatai),
      'chi' => %(Chinese),
      'chk' => %(Truk),
      'chm' => %(Mari),
      'chn' => %(Chinook jargon),
      'cho' => %(Choctaw),
      'chp' => %(Chipewyan),
      'chr' => %(Cherokee),
      'chu' => %(Church Slavic),
      'chv' => %(Chuvash),
      'chy' => %(Cheyenne),
      'cmc' => %(Chamic languages),
      'cop' => %(Coptic),
      'cor' => %(Cornish),
      'cos' => %(Corsican),
      'cpe' => %(Creoles and Pidgins, English-based (Other)),
      'cpf' => %(Creoles and Pidgins, French-based (Other)),
      'cpp' => %(Creoles and Pidgins, Portuguese-based (Other)),
      'cre' => %(Cree),
      'crh' => %(Crimean Tatar),
      'crp' => %(Creoles and Pidgins (Other)),
      'cus' => %(Cushitic (Other)),
      'cze' => %(Czech),
      'dak' => %(Dakota),
      'dan' => %(Danish),
      'dar' => %(Dargwa),
      'day' => %(Dayak),
      'del' => %(Delaware),
      'den' => %(Slave),
      'dgr' => %(Dogrib),
      'din' => %(Dinka),
      'div' => %(Divehi),
      'doi' => %(Dogri),
      'dra' => %(Dravidian (Other)),
      'dua' => %(Duala),
      'dum' => %(Dutch, Middle (ca. 1050-1350)),
      'dut' => %(Dutch),
      'dyu' => %(Dyula),
      'dzo' => %(Dzongkha),
      'efi' => %(Efik),
      'egy' => %(Egyptian),
      'eka' => %(Ekajuk),
      'elx' => %(Elamite),
      'eng' => %(English),
      'enm' => %(English, Middle (1100-1500)),
      'epo' => %(Esperanto),
      'esk' => %(Eskimo languages),
      'esp' => %(Esperanto),
      'est' => %(Estonian),
      'eth' => %(Ethiopic),
      'ewe' => %(Ewe),
      'ewo' => %(Ewondo),
      'fan' => %(Fang),
      'fao' => %(Faroese),
      'far' => %(Faroese),
      'fat' => %(Fanti),
      'fij' => %(Fijian),
      'fin' => %(Finnish),
      'fiu' => %(Finno-Ugrian (Other)),
      'fon' => %(Fon),
      'fre' => %(French),
      'fri' => %(Frisian),
      'frm' => %(French, Middle (ca. 1400-1600)),
      'fro' => %(French, Old (ca. 842-1400)),
      'fry' => %(Frisian),
      'ful' => %(Fula),
      'fur' => %(Friulian),
      'gaa' => %(Ga),
      'gae' => %(Scottish Gaelic),
      'gag' => %(Galician),
      'gal' => %(Oromo),
      'gay' => %(Gayo),
      'gba' => %(Gbaya),
      'gem' => %(Germanic (Other)),
      'geo' => %(Georgian),
      'ger' => %(German),
      'gez' => %(Ethiopic),
      'gil' => %(Gilbertese),
      'gla' => %(Scottish Gaelic),
      'gle' => %(Irish),
      'glg' => %(Galician),
      'glv' => %(Manx),
      'gmh' => %(German, Middle High (ca. 1050-1500)),
      'goh' => %(German, Old High (ca. 750-1050)),
      'gon' => %(Gondi),
      'gor' => %(Gorontalo),
      'got' => %(Gothic),
      'grb' => %(Grebo),
      'grc' => %(Greek, Ancient (to 1453)),
      'gre' => %(Greek, Modern (1453- )),
      'grn' => %(Guarani),
      'gua' => %(Guarani),
      'guj' => %(Gujarati),
      'gwi' => %(Gwich'in),
      'hai' => %(Haida),
      'hat' => %(Haitian French Creole),
      'hau' => %(Hausa),
      'haw' => %(Hawaiian),
      'heb' => %(Hebrew),
      'her' => %(Herero),
      'hil' => %(Hiligaynon),
      'him' => %(Himachali),
      'hin' => %(Hindi),
      'hit' => %(Hittite),
      'hmn' => %(Hmong),
      'hmo' => %(Hiri Motu),
      'hun' => %(Hungarian),
      'hup' => %(Hupa),
      'iba' => %(Iban),
      'ibo' => %(Igbo),
      'ice' => %(Icelandic),
      'ido' => %(Ido),
      'iii' => %(Sichuan Yi),
      'ijo' => %(Ijo),
      'iku' => %(Inuktitut),
      'ile' => %(Interlingue),
      'ilo' => %(Iloko),
      'ina' => %(Interlingua (International Auxiliary Language Association)),
      'inc' => %(Indic (Other)),
      'ind' => %(Indonesian),
      'ine' => %(Indo-European (Other)),
      'inh' => %(Ingush),
      'int' => %(Interlingua (International Auxiliary Language Association)),
      'ipk' => %(Inupiaq),
      'ira' => %(Iranian (Other)),
      'iri' => %(Irish),
      'iro' => %(Iroquoian (Other)),
      'ita' => %(Italian),
      'jav' => %(Javanese),
      'jpn' => %(Japanese),
      'jpr' => %(Judeo-Persian),
      'jrb' => %(Judeo-Arabic),
      'kaa' => %(Kara-Kalpak),
      'kab' => %(Kabyle),
      'kac' => %(Kachin),
      'kal' => %(Kalatdlisut),
      'kam' => %(Kamba),
      'kan' => %(Kannada),
      'kar' => %(Karen),
      'kas' => %(Kashmiri),
      'kau' => %(Kanuri),
      'kaw' => %(Kawi),
      'kaz' => %(Kazakh),
      'kbd' => %(Kabardian),
      'kha' => %(Khasi),
      'khi' => %(Khoisan (Other)),
      'khm' => %(Khmer),
      'kho' => %(Khotanese),
      'kik' => %(Kikuyu),
      'kin' => %(Kinyarwanda),
      'kir' => %(Kyrgyz),
      'kmb' => %(Kimbundu),
      'kok' => %(Konkani),
      'kom' => %(Komi),
      'kon' => %(Kongo),
      'kor' => %(Korean),
      'kos' => %(Kusaie),
      'kpe' => %(Kpelle),
      'kro' => %(Kru),
      'kru' => %(Kurukh),
      'kua' => %(Kuanyama),
      'kum' => %(Kumyk),
      'kur' => %(Kurdish),
      'kus' => %(Kusaie),
      'kut' => %(Kutenai),
      'lad' => %(Ladino),
      'lah' => %(Lahnda),
      'lam' => %(Lamba),
      'lan' => %(Occitan (post-1500)),
      'lao' => %(Lao),

      'lap' => %(Sami),
      'lat' => %(Latin),
      'lav' => %(Latvian),
      'lez' => %(Lezgian),
      'lim' => %(Limburgish),
      'lin' => %(Lingala),
      'lit' => %(Lithuanian),
      'lol' => %(Mongo-Nkundu),
      'loz' => %(Lozi),
      'ltz' => %(Letzeburgesch),
      'lua' => %(Luba-Lulua),
      'lub' => %(Luba-Katanga),
      'lug' => %(Ganda),
      'lui' => %(Luiseno),
      'lun' => %(Lunda),
      'luo' => %(Luo (Kenya and Tanzania)),
      'lus' => %(Lushai),
      'mac' => %(Macedonian),
      'mad' => %(Madurese),
      'mag' => %(Magahi),
      'mah' => %(Marshallese),
      'mai' => %(Maithili),
      'mak' => %(Makasar),
      'mal' => %(Malayalam),
      'man' => %(Mandingo),
      'mao' => %(Maori),
      'map' => %(Austronesian (Other)),
      'mar' => %(Marathi),
      'mas' => %(Masai),
      'max' => %(Manx),
      'may' => %(Malay),
      'mdr' => %(Mandar),
      'men' => %(Mende),
      'mga' => %(Irish, Middle (ca. 1100-1550)),
      'mic' => %(Micmac),
      'min' => %(Minangkabau),
      'mis' => %(Miscellaneous languages),
      'mkh' => %(Mon-Khmer (Other)),
      'mla' => %(Malagasy),
      'mlg' => %(Malagasy),
      'mlt' => %(Maltese),
      'mnc' => %(Manchu),
      'mni' => %(Manipuri),
      'mno' => %(Manobo languages),
      'moh' => %(Mohawk),
      'mol' => %(Moldavian),
      'mon' => %(Mongolian),
      'mos' => %(Moore),
      'mul' => %(Multiple languages),
      'mun' => %(Munda (Other)),
      'mus' => %(Creek),
      'mwr' => %(Marwari),
      'myn' => %(Mayan languages),
      'nah' => %(Nahuatl),
      'nai' => %(North American Indian (Other)),
      'nap' => %(Neapolitan Italian),
      'nau' => %(Nauru),
      'nav' => %(Navajo),
      'nbl' => %(Ndebele (South Africa)),
      'nde' => %(Ndebele (Zimbabwe)),
      'ndo' => %(Ndonga),
      'nds' => %(Low German),
      'nep' => %(Nepali),
      'new' => %(Newari),
      'nia' => %(Nias),
      'nic' => %(Niger-Kordofanian (Other)),
      'niu' => %(Niuean),
      'nno' => %(Norwegian (Nynorsk)),
      'nob' => %(Norwegian (Bokmal)),
      'nog' => %(Nogai),
      'non' => %(Old Norse),
      'nor' => %(Norwegian),
      'nso' => %(Northern Sotho),
      'nub' => %(Nubian languages),
      'nya' => %(Nyanja),
      'nym' => %(Nyamwezi),
      'nyn' => %(Nyankole),
      'nyo' => %(Nyoro),
      'nzi' => %(Nzima),
      'oci' => %(Occitan (post-1500)),
      'oji' => %(Ojibwa),
      'ori' => %(Oriya),
      'orm' => %(Oromo),
      'osa' => %(Osage),
      'oss' => %(Ossetic),
      'ota' => %(Turkish, Ottoman),
      'oto' => %(Otomian languages),
      'paa' => %(Papuan (Other)),
      'pag' => %(Pangasinan),
      'pal' => %(Pahlavi),
      'pam' => %(Pampanga),
      'pan' => %(Panjabi),
      'pap' => %(Papiamento),
      'pau' => %(Palauan),
      'peo' => %(Old Persian (ca. 600-400 B.C.)),
      'per' => %(Persian),
      'phi' => %(Philippine (Other)),
      'phn' => %(Phoenician),
      'pli' => %(Pali),
      'pol' => %(Polish),
      'pon' => %(Ponape),
      'por' => %(Portuguese),
      'pra' => %(Prakrit languages),
      'pro' => %(Provencal (to 1500)),
      'pus' => %(Pushto),
      'que' => %(Quechua),
      'raj' => %(Rajasthani),
      'rap' => %(Rapanui),
      'rar' => %(Rarotongan),
      'roa' => %(Romance (Other)),
      'roh' => %(Raeto-Romance),
      'rom' => %(Romani),
      'rum' => %(Romanian),
      'run' => %(Rundi),
      'rus' => %(Russian),
      'sad' => %(Sandawe),
      'sag' => %(Sango (Ubangi Creole)),
      'sah' => %(Yakut),
      'sai' => %(South American Indian (Other)),
      'sal' => %(Salishan languages),
      'sam' => %(Samaritan Aramaic),
      'san' => %(Sanskrit),
      'sao' => %(Samoan),
      'sas' => %(Sasak),
      'sat' => %(Santali),
      'scc' => %(Serbian),
      'sco' => %(Scots),
      'scr' => %(Croatian),
      'sel' => %(Selkup),
      'sem' => %(Semitic (Other)),
      'sga' => %(Irish, Old (to 1100)),
      'sgn' => %(Sign languages),
      'shn' => %(Shan),
      'sho' => %(Shona),
      'sid' => %(Sidamo),
      'sin' => %(Sinhalese),
      'sio' => %(Siouan (Other)),
      'sit' => %(Sino-Tibetan (Other)),
      'sla' => %(Slavic (Other)),
      'slo' => %(Slovak),
      'slv' => %(Slovenian),
      'sma' => %(Southern Sami),
      'sme' => %(Northern Sami),
      'smi' => %(Sami),
      'smj' => %(Lule Sami),
      'smn' => %(Inari Sami),
      'smo' => %(Samoan),
      'sms' => %(Skolt Sami),
      'sna' => %(Shona),
      'snd' => %(Sindhi),
      'snh' => %(Sinhalese),
      'snk' => %(Soninke),
      'sog' => %(Sogdian),
      'som' => %(Somali),
      'son' => %(Songhai),
      'sot' => %(Sotho),
      'spa' => %(Spanish),
      'srd' => %(Sardinian),
      'srr' => %(Serer),
      'ssa' => %(Nilo-Saharan (Other)),
      'sso' => %(Sotho),
      'ssw' => %(Swazi),
      'suk' => %(Sukuma),
      'sun' => %(Sundanese),
      'sus' => %(Susu),
      'sux' => %(Sumerian),
      'swa' => %(Swahili),
      'swe' => %(Swedish),
      'swz' => %(Swazi),
      'syr' => %(Syriac),
      'tag' => %(Tagalog),
      'tah' => %(Tahitian),
      'tai' => %(Tai (Other)),
      'taj' => %(Tajik),
      'tam' => %(Tamil),
      'tar' => %(Tatar),
      'tat' => %(Tatar),
      'tel' => %(Telugu),
      'tem' => %(Temne),
      'ter' => %(Terena),
      'tet' => %(Tetum),
      'tgk' => %(Tajik),
      'tgl' => %(Tagalog),
      'tha' => %(Thai),
      'tib' => %(Tibetan),
      'tig' => %(Tigre),
      'tir' => %(Tigrinya),
      'tiv' => %(Tiv),
      'tkl' => %(Tokelauan),
      'tli' => %(Tlingit),
      'tmh' => %(Tamashek),
      'tog' => %(Tonga (Nyasa)),
      'ton' => %(Tongan),
      'tpi' => %(Tok Pisin),
      'tru' => %(Truk),
      'tsi' => %(Tsimshian),
      'tsn' => %(Tswana),
      'tso' => %(Tsonga),
      'tsw' => %(Tswana),
      'tuk' => %(Turkmen),
      'tum' => %(Tumbuka),
      'tup' => %(Tupi languages),
      'tur' => %(Turkish),
      'tut' => %(Altaic (Other)),
      'tvl' => %(Tuvaluan),
      'twi' => %(Twi),
      'tyv' => %(Tuvinian),
      'udm' => %(Udmurt),
      'uga' => %(Ugaritic),
      'uig' => %(Uighur),
      'ukr' => %(Ukrainian),
      'umb' => %(Umbundu),
      'und' => %(Undetermined),
      'urd' => %(Urdu),
      'uzb' => %(Uzbek),
      'vai' => %(Vai),
      'ven' => %(Venda),
      'vie' => %(Vietnamese),
      'vol' => %(Volapuk),
      'vot' => %(Votic),
      'wak' => %(Wakashan languages),
      'wal' => %(Walamo),
      'war' => %(Waray),
      'was' => %(Washo),
      'wel' => %(Welsh),
      'wen' => %(Sorbian languages),
      'wln' => %(Walloon),
      'wol' => %(Wolof),
      'xal' => %(Kalmyk),
      'xho' => %(Xhosa),
      'yao' => %(Yao (Africa)),
      'yap' => %(Yapese),
      'yid' => %(Yiddish),
      'yor' => %(Yoruba),
      'ypk' => %(Yupik languages),
      'zap' => %(Zapotec),
      'zen' => %(Zenaga),
      'zha' => %(Zhuang),
      'znd' => %(Zande),
      'zul' => %(Zulu),
      'zun' => %(Zuni),
      'zxx' => ''
    }

  end
  
end
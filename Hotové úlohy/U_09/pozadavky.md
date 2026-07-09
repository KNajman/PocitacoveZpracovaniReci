
gramatika grammar
'''
$digit = JEDNA | DVA | TRI | CTYRI | PET | SEST | SEDM | OSM | DEVET | NULA;
( SENT-START ( $digit ) SENT-END )
'''
slovnik lexicon
'''
CTYRI ctyri
DEVET devet
DVA dva
JEDNA jedna
NULA nula
OSM osm
PET pet
SEDM sedm
SENT-END [] sil
SENT-START [] sil
SEST sest
TRI tri

PLUS plus
MINUS minus
KRAT krat
DELENO deleno
LOMENO lomeno
NADRUHOU
ODMOCNINA odmocnina
PROCENT procent
PLUSMINUS plusminus
CARKA carka
TECKA tecka
ROVNASE rovnase
ROVNOST rovnast
SMAZAT smazat
VYMAZAT vymazat
'''





pro každý soubor v adresáři ~/DATA2/UnknownSpeakers/ vygenerovat soubor s názvem <jméno souboru>.lab s obsahem:
název čísla souboru je nutné změnit číslovku na slovo bez interpunkce a mezer

název souboru je složen "c%1d_p%4d_s%2d.wav" kde c je číslo, p je osoba a s je nahrávka
'''
    sil
    [0-9] na [nula, jedna, dva, tri, ctyri, pet, sest, sedm, osm, devet]
    sil
'''


MLF (Master Lab File) – zavedeny proto, aby se v rámci procesu
trénování a testování zredukoval počet otevíraných textových souborů.
V jediném souboru jsou všechny informace nutné pro trénování (train.mlf),
testování (výsledný soubor recout.mlf) a vyhodnocování (testref.mlf)
Na prvním řádku je vždy hlavička #!MLF!#, pak následuje vždy název souboru LAB
a na dalších řádcích relevantní údaje zakončené řádkou se znakem tečka.
Ukázka train.mlf
#!MLF!#
"D:/HTK/DATA/0000_MVL/c0_p0000_s00.lab"
sil
nula
sil
.
"D:/HTK/DATA/0000_MVL/c0_p0000_s01.lab"
sil
nula
sil
.
Ukázka testref.mlf
#!MLF!#
"D:/HTK/DATA/0000_MVL/c0_p0000_s04.lab"
NULA
.
"D:/HTK/DATA/0000_MVL/c1_p0000_s04.lab"
JEDNA
.

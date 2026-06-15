# Aplikace pro hlasové ovládání kalkulačky

Tento projekt jsem vytvořil v rámci závěrečné úlohy předmětu Počítačové zpracování řeči. Jako cíl jsem si vybral hlasové ovládání standardní Windows kalkulačky pomocí rozpoznávače založeného na "skrytých" Markovových modelech.

## Zadání úlohy

Úkolem bylo vytvořit hlasové ovládání jednoduché aplikace pomocí přibližně 15 až 20 povelů. Rozpoznávač měl být založený na skrytých Markovových modelech nebo DTW a natrénovaný na datech od minimálně dvou osob. Součástí zadání byl také zvukový modul, který v nekonečném cyklu zachytává přibližně dvousekundové nahrávky, rozpozná je a následně provede požadovanou akci bez nutnosti použití klávesnice. Požadovaná přesnost rozpoznávání byla stanovena na více než 90 procent pro modely závislé na mluvčím.

## Popis aplikace

Aplikaci jsem napsal v prostředí MATLAB s využitím grafického rozhraní App Designer. Po spuštění moje aplikace automaticky v nekonečné smyčce nahrává zvuk z mikrofonu. Pokud po překročení prahu hlasitosti zachytí řeč, zvukový signál vykreslí do grafu, uloží ho a odešle k parametrizaci a rozpoznání nástrojům z balíku HTK. Během tohoto procesu aplikace vytvoří dočasné soubory live_input.mfc a live_res.mlf. Výsledek z HTK následně přečtu MATLABem a pomocí knihovny java.awt.Robot nasimuluji stisk odpovídající klávesy či klávesové zkratky do aktuálně aktivního okna, kterým je standardní Windows kalkulačka.

## Řešení a trénovací data

Jádrem mého rozpoznávače je sada HMM modelů, která pracuje s MFCC příznaky. O kompletní zpracování řeči se stará balík HTK ve spolupráci se sadou podpůrných MATLAB skriptů, které jsem naprogramoval a upravil během semestru. Nahrávky jsem pořídil já, tedy Karel Najman, a můj spolubydlící Jan. Pro každý povel jsem od každého řečníka nahrál sedm zvukových stop. Pět nahrávek jsem použil pro trénování modelů a zbylé dvě nahrávky jsem vyhradil pro testování a evaluaci úspěšnosti. Celkem můj systém rozpoznává 22 unikátních slov, mezi které patří číslovky, matematické operace a povely pro mazání.

## Gramatika a povely

Rozpoznávač očekává izolovaná slova ohraničená tichem, která se značí jako SENT-START a SENT-END. Příkazy pro ovládání kalkulačky jsem definoval v následující gramatice.

```bash
$digit = NULA | JEDNA | DVA | TRI | CTYRI | PET | SEST | SEDM | OSM | DEVET ;
$operation = PLUS | MINUS | KRAT | DELENO | NADRUHOU | ODMOCNINA | PROCENT | PLUSMINUS ;
$command = ROVNASE | SMAZAT | VYMAZAT | ZPET ;
$separator = CARKA ;

( SENT-START < $digit | $operation | $command | $separator > SENT-END )
```

## Postup vytvoření a trénování modelu

Pro reprodukci celého procesu trénování a testování jsem víceméně pomocí MATLAB skriptů zautomatizoval přípravy pro dávkové soubory Z CVIČENÍ které volají programy balíku HTK postup je následující:

1. Vytvořit si **gramatiku** a soubor **wlist**.

2. Spustit dávku **01_MakeWordnet.bat** pro vytvoření slovní sítě (wordnet).

3. Pomocí dávky **02_MakeDictionary.bat** jsem vygenerovat slovník.

4. Pro pořízení nahrávek jsem v MATLABu naprogramoval a spustil skript **nahravani.m**, který projedu všechny slova s wlistu, ořízně začátky a konce pomocí detekce hlasové aktivity, a zařadí hlasové nahrávky do složky nahravky. Každý soubor jsem pojmenoval podle vzoru: ```<mluvčí>_<slovo>_<číslo_nahravky>.wav```.

5. Připravil jsem seznamy pro parametrizaci spuštěním skriptu **pripravaProHCopy.m**, čímž jsem vytvořil složku *nahravky_param* a seznam *param.list*. Následně jsem spustil skript **pripravaTest.m**, který vytvořil složku test_param a seznamy pro testovací data.

6. Zvukové soubory jsem parametrizoval převodem do formátu MFC pomocí dávky **03_DoParameterization.bat**.

7. Popisky MLF jsem připravil spuštěním mých MATLAB skriptů **generate_trainMLF.m** a **generate_testMLF.m**.

8. Inicializaci modelů výpočtem globálních variancí pomocí dávky **04_ComputeVariances.bat**.

9. Pro dynamické vytvoření HMM definic, konkrétně souborů hmmdefs a macros, jsem naprogramoval a spustil skript **pripravaProHERest.m**.

10. Modely jsou iterativně natrénovány pomocí spuštěním dávky **05_TrainModels.bat**, kontrétně progamem HERest, který aktualizuje parametry modelů na základě trénovacích dat. Kontrétně proběhne 6 iterací.

11. Rozpoznávač je zkompilován dávkou **06_GrammarCompilation.bat**.

12. Modely se otestují pomocí dávky **10_RunTest.bat**, která provedede rozpoznání na testovacích datech prostřednictvím nástroje HVite.

13. Celý rozpoznávač je vyhodnocen tak, že jsem si skriptem **pripravaProHResults.m** připravil referenční MLF soubor a dávkou **11_ComputeResults.bat** která spočítá a zobrazit celkovou přesnost rozpoznávače.

```bash
====================== HTK Results Analysis =======================
  Date: Thu Jun 11 23:05:21 2026
  Ref : testref.mlf
  Rec : recout.mlf
------------------------ Overall Results --------------------------
SENT: %Correct=96.74 [H=89, S=3, N=92]
WORD: %Corr=96.74, Acc=96.74 [H=89, D=0, S=3, I=0, N=92]
===================================================================
```

Úspěšnost mého rozpoznávače pro testovací data dosáhla 96.74 procent, což splňuje požadavek zadání.

14. Po úspěšném natrénování modelů jsem v MATLABu pomocí AppDesigneru připravil grafické rozhraní pro zachytávání zvuku, jeho parametrizaci a odesílání k rozpoznání. Po spuštění aplikace se v nekonečné smyčce nahrává zvuk z mikrofonu, a pokud je detekována řeč, provede se rozpoznání a následně se pomocí java.awt.Robot nasimuluje stisk klávesy pro kalkulačku.
# -*- coding: utf-8 -*-
"""Generate localized store listing texts (Google Play + App Store) for all 13 languages.

Layout (fastlane-compatible for Play):
  store/listings/play/<locale>/{title,short_description,full_description}.txt
  store/listings/ios/<locale>/{name,subtitle,promotional_text,description,keywords}.txt
Limits enforced: Play 30/80/4000; iOS 30/30/170/4000/100.
"""
import io, os

REPO = r"C:\Users\Brad\StudioProjects\nuptialflight\.claude\worktrees\app-review-overhaul-dbc88c"

# (play_locale, ios_locale or None)
LOCALE_MAP = {
    'en': ('en-US', 'en-US'), 'tr': ('tr-TR', 'tr'), 'fil': ('fil', None),
    'es': ('es-ES', 'es-ES'), 'fr': ('fr-FR', 'fr-FR'), 'de': ('de-DE', 'de-DE'),
    'pl': ('pl-PL', 'pl'), 'cs': ('cs-CZ', 'cs'), 'el': ('el-GR', 'el'),
    'pt': ('pt-BR', 'pt-BR'), 'nl': ('nl-NL', 'nl-NL'), 'id': ('id', 'id'),
    'ms': ('ms', 'ms'),
}

L = {}

L['en'] = dict(
 title="Ant Nuptial Flight Predictor",
 short="Know when queen ants will fly. AI forecast trained on real sightings worldwide.",
 subtitle="Know when queen ants will fly",
 promo="New: the Ant Flight Index - clear day ratings, honest odds and 13 languages. The forecast is trained on 10,000+ real sightings from ant keepers worldwide.",
 keywords="ants,ant,queen,nuptial,flight,flying,antkeeping,formicarium,colony,swarm,alates,weather,forecast",
 full="""Will they fly today?

Every ant colony waits for the perfect day - then fills the sky with winged queens on their nuptial flight. Ant keepers wait for the same day. This app tells you when it's coming.

THE ANT FLIGHT INDEX
Instead of a meaningless percentage, every day gets a clear rating - No-fly, Quiet, Watchful, Promising or Prime - based on how today's weather compares with years of historical days at your latitude and time of year. Prime means the top ~10% of days in your season: drop everything and get outside.

HONEST ODDS
"About 1 in 7 days like this see a reported flight." Calibrated against thousands of real sightings - never a made-up probability.

HOUR BY HOUR
Flight confidence for the next 24 hours, the best three-hour window to go looking, and the week ahead at a glance.

WHY THIS FORECAST?
Full transparency: see exactly how temperature, wind, humidity, cloud, rain and pressure moved today's rating - straight from the model, no hand-waving.

POWERED BY ANT KEEPERS
The forecast is a machine-learning model trained on 10,000+ real flight reports from users worldwide. Report a sighting (or "I looked - no flights") and you make it smarter for everyone.

ALSO IN THE BOX
- Prime-day notifications - only when it matters
- Home-screen widgets for Android and iPhone
- Live map of recent sightings near you
- Which queen size is in season (small / medium / large)
- Dark mode, C/F units, and 13 languages
- Free and open source. No ads, no tracking.

Made by an ant keeper, for ant keepers - and for anyone who has ever wondered why the sky is suddenly full of flying ants.""",
)

L['tr'] = dict(
 title="Karinca Ucus Tahmini",
 title_native="Karınca Uçuş Tahmini",
 short="Kraliçe karıncalar ne zaman uçacak? Gerçek gözlemlerle eğitilen yapay zeka.",
 subtitle="Kraliçeler ne zaman uçacak?",
 promo="Yeni: Karınca Uçuş Endeksi - net gün dereceleri, dürüst olasılıklar ve 13 dil. Tahmin, dünya çapında 10.000+ gerçek gözlemle eğitildi.",
 keywords="karinca,kralice,ucus,ciftlesme,ucan,formikaryum,koloni,hava,tahmin,mevsim",
 full="""Bugün uçacaklar mı?

Her karınca kolonisi mükemmel günü bekler - sonra gökyüzü çiftleşme uçuşuna çıkan kanatlı kraliçelerle dolar. Karınca besleyenler de aynı günü bekler. Bu uygulama o günün ne zaman geleceğini söyler.

KARINCA UÇUŞ ENDEKSİ
Anlamsız bir yüzde yerine her gün net bir derece alır: Uçuş yok, Sakin, Dikkatli, Umut verici veya Mükemmel. Derece, bugünkü havanın enleminizde ve mevsiminizde yıllardır görülen günlerle karşılaştırılmasına dayanır. Mükemmel, sezonunuzun en iyi ~%10'luk günleri demektir: her şeyi bırakıp dışarı çıkın.

DÜRÜST OLASILIKLAR
"Böyle günlerin yaklaşık 7'sinden 1'inde uçuş bildirilir." Binlerce gerçek gözlemle kalibre edilmiştir - asla uydurma bir olasılık değildir.

SAAT SAAT
Önümüzdeki 24 saatin uçuş güveni, bakmak için en iyi üç saatlik aralık ve haftanın görünümü.

BU TAHMİN NEDEN?
Tam şeffaflık: sıcaklık, rüzgar, nem, bulut, yağmur ve basıncın bugünkü dereceyi nasıl etkilediğini doğrudan modelden görün.

KARINCA BESLEYENLERİN GÜCÜYLE
Tahmin, dünya çapında kullanıcıların 10.000'den fazla gerçek uçuş bildirimiyle eğitilen bir makine öğrenmesi modelidir. Bir gözlem bildirin (veya "Baktım - uçuş yok" deyin), tahmini herkes için daha akıllı yapın.

AYRICA
- Sadece Mükemmel günlerde bildirim
- Android ve iPhone ana ekran widget'ları
- Yakınınızdaki son gözlemlerin canlı haritası
- Hangi kraliçe boyunun mevsiminde olduğu (küçük / orta / büyük)
- Karanlık mod, C/F birimleri ve 13 dil
- Ücretsiz ve açık kaynak. Reklamsız, izlemesiz.

Bir karınca besleyici tarafından, karınca besleyenler için yapıldı - ve gökyüzünün neden aniden uçan karıncalarla dolduğunu merak eden herkes için.""",
)

L['fil'] = dict(
 title="Ant Nuptial Flight Predictor",
 short="Alamin kung kailan lilipad ang mga reyna. AI na sinanay sa totoong mga ulat.",
 subtitle="Kailan lilipad ang mga reyna?",
 promo="Bago: ang Ant Flight Index - malinaw na rating bawat araw, tapat na tsansa, at 13 wika. Sinanay sa 10,000+ totoong ulat mula sa buong mundo.",
 keywords="langgam,reyna,lipad,nuptial,flight,antkeeping,kolonya,panahon,hula",
 full="""Lilipad ba sila ngayon?

Naghihintay ang bawat kolonya ng langgam ng perpektong araw - saka pupunuin ang langit ng mga may pakpak na reyna sa kanilang nuptial flight. Ganoon din ang mga nag-aalaga ng langgam. Sasabihin ng app na ito kung kailan darating ang araw na iyon.

ANG ANT FLIGHT INDEX
Sa halip na walang kwentang porsyento, bawat araw ay may malinaw na rating - Walang lipad, Tahimik, Bantayan, Promising o Prime - batay sa paghahambing ng panahon ngayon sa mga nakaraang taon sa inyong latitude at panahon ng taon. Ang Prime ay nasa nangungunang ~10% ng mga araw sa inyong season: iwanan ang lahat at lumabas.

TAPAT NA TSANSA
"Humigit-kumulang 1 sa 7 araw na ganito ang may naiulat na lipad." Na-calibrate sa libu-libong totoong ulat - hindi kailanman imbentong probabilidad.

BAWAT ORAS
Kumpiyansa ng paglipad sa susunod na 24 oras, ang pinakamagandang tatlong-oras na pagkakataon, at ang buong linggo sa isang tingin.

BAKIT GANITO ANG HULA?
Buong transparency: makikita mo mismo kung paano ginalaw ng temperatura, hangin, halumigmig, ulap, ulan at presyon ang rating ngayon - direkta mula sa model.

PINAPAGANA NG MGA ANT KEEPER
Ang hula ay isang machine-learning model na sinanay sa 10,000+ totoong ulat ng lipad mula sa mga user sa buong mundo. Mag-ulat ng nakita mo (o "Tumingin ako - walang lipad") at gagawin mo itong mas matalino para sa lahat.

KASAMA RIN
- Notification tuwing Prime na araw lang
- Widget sa home screen para sa Android at iPhone
- Live na mapa ng mga kamakailang ulat malapit sa iyo
- Kung aling laki ng reyna ang nasa season (maliit / katamtaman / malaki)
- Dark mode, C/F, at 13 wika
- Libre at open source. Walang ads, walang tracking.

Gawa ng isang ant keeper, para sa mga ant keeper - at para sa sinumang nagtaka kung bakit biglang puno ng lumilipad na langgam ang langit.""",
)

L['es'] = dict(
 title="Predictor de Vuelo de Hormigas",
 short="Sabe cuándo volarán las reinas. IA entrenada con avistamientos reales.",
 subtitle="¿Cuándo volarán las reinas?",
 promo="Nuevo: el Índice de Vuelo - valoraciones claras por día, probabilidades honestas y 13 idiomas. Entrenado con más de 10.000 avistamientos reales de todo el mundo.",
 keywords="hormigas,hormiga,reina,vuelo,nupcial,voladoras,hormiguero,colonia,enjambre,tiempo,pronostico",
 full="""¿Volarán hoy?

Cada colonia de hormigas espera el día perfecto - y entonces llena el cielo de reinas aladas en su vuelo nupcial. Los criadores de hormigas esperan el mismo día. Esta app te dice cuándo llega.

EL ÍNDICE DE VUELO
En lugar de un porcentaje sin sentido, cada día recibe una valoración clara: Sin vuelo, Tranquilo, Atento, Prometedor u Óptimo, según cómo se compara el tiempo de hoy con años de días históricos en tu latitud y época del año. Óptimo significa el ~10% mejor de los días de tu temporada: déjalo todo y sal.

PROBABILIDADES HONESTAS
"Aproximadamente 1 de cada 7 días como este registra un vuelo." Calibrado con miles de avistamientos reales - nunca una probabilidad inventada.

HORA A HORA
La confianza de vuelo de las próximas 24 horas, la mejor franja de tres horas para salir a mirar y la semana de un vistazo.

¿POR QUÉ ESTE PRONÓSTICO?
Transparencia total: ve exactamente cómo la temperatura, el viento, la humedad, las nubes, la lluvia y la presión movieron la valoración de hoy - directo del modelo.

IMPULSADO POR CRIADORES DE HORMIGAS
El pronóstico es un modelo de aprendizaje automático entrenado con más de 10.000 informes reales de vuelos de usuarios de todo el mundo. Informa de un avistamiento (o "Miré - sin vuelos") y lo haces más inteligente para todos.

ADEMÁS
- Notificaciones solo en días Óptimos
- Widgets de pantalla de inicio para Android y iPhone
- Mapa en vivo de avistamientos recientes cerca de ti
- Qué tamaño de reina está en temporada (pequeña / mediana / grande)
- Modo oscuro, unidades C/F y 13 idiomas
- Gratis y de código abierto. Sin anuncios ni rastreo.

Hecho por un criador de hormigas, para criadores de hormigas - y para cualquiera que se haya preguntado por qué el cielo se llena de repente de hormigas voladoras.""",
)

L['fr'] = dict(
 title="Vol Nuptial des Fourmis",
 short="Sachez quand les reines voleront. IA entraînée sur de vraies observations.",
 subtitle="Quand les reines voleront",
 promo="Nouveau : l'Indice de Vol - des notes claires par jour, des probabilités honnêtes et 13 langues. Entraîné sur plus de 10 000 observations réelles dans le monde.",
 keywords="fourmis,fourmi,reine,vol,nuptial,volantes,fourmiliere,colonie,essaimage,meteo,prevision",
 full="""Voleront-elles aujourd'hui ?

Chaque colonie de fourmis attend le jour parfait - puis remplit le ciel de reines ailées pour leur vol nuptial. Les éleveurs de fourmis attendent le même jour. Cette appli vous dit quand il arrive.

L'INDICE DE VOL
Au lieu d'un pourcentage sans signification, chaque jour reçoit une note claire : Aucun vol, Calme, À surveiller, Prometteur ou Idéal, selon la comparaison de la météo du jour avec des années de journées historiques à votre latitude et à cette période de l'année. Idéal signifie le top ~10 % des jours de votre saison : laissez tout et sortez.

DES PROBABILITÉS HONNÊTES
« Environ 1 jour sur 7 comme celui-ci donne lieu à un vol signalé. » Calibré sur des milliers d'observations réelles - jamais une probabilité inventée.

HEURE PAR HEURE
La confiance de vol des prochaines 24 heures, le meilleur créneau de trois heures pour aller observer, et la semaine en un coup d'œil.

POURQUOI CETTE PRÉVISION ?
Transparence totale : voyez exactement comment température, vent, humidité, nuages, pluie et pression ont influencé la note du jour - directement depuis le modèle.

PROPULSÉ PAR LES ÉLEVEURS
La prévision est un modèle d'apprentissage automatique entraîné sur plus de 10 000 signalements réels de vols d'utilisateurs du monde entier. Signalez une observation (ou « J'ai regardé - aucun vol ») et vous le rendez plus intelligent pour tous.

ET AUSSI
- Notifications uniquement les jours Idéals
- Widgets d'écran d'accueil pour Android et iPhone
- Carte en direct des observations récentes près de vous
- Quelle taille de reine est de saison (petite / moyenne / grande)
- Mode sombre, unités C/F et 13 langues
- Gratuit et open source. Sans pub, sans pistage.

Créé par un éleveur de fourmis, pour les éleveurs de fourmis - et pour quiconque s'est déjà demandé pourquoi le ciel se remplit soudain de fourmis volantes.""",
)

L['de'] = dict(
 title="Hochzeitsflug-Vorhersage",
 short="Wissen, wann Königinnen fliegen. KI-Prognose aus echten Sichtungen weltweit.",
 subtitle="Wann fliegen die Königinnen?",
 promo="Neu: der Ameisenflug-Index - klare Tagesbewertungen, ehrliche Chancen und 13 Sprachen. Trainiert mit über 10.000 echten Sichtungen aus aller Welt.",
 keywords="ameisen,ameise,koenigin,hochzeitsflug,schwarmflug,fliegend,formicarium,kolonie,wetter,vorhersage",
 full="""Fliegen sie heute?

Jede Ameisenkolonie wartet auf den perfekten Tag - dann füllt sie den Himmel mit geflügelten Königinnen auf ihrem Hochzeitsflug. Ameisenhalter warten auf denselben Tag. Diese App sagt dir, wann er kommt.

DER AMEISENFLUG-INDEX
Statt einer bedeutungslosen Prozentzahl bekommt jeder Tag eine klare Bewertung: Kein Flug, Ruhig, Wachsam, Vielversprechend oder Erstklassig - je nachdem, wie das heutige Wetter im Vergleich zu Jahren historischer Tage auf deinem Breitengrad und zu dieser Jahreszeit abschneidet. Erstklassig heißt: die besten ~10 % der Tage deiner Saison - alles stehen lassen und raus.

EHRLICHE CHANCEN
"Etwa an 1 von 7 Tagen wie diesem wird ein Flug gemeldet." Kalibriert an Tausenden echter Sichtungen - nie eine erfundene Wahrscheinlichkeit.

STUNDE FÜR STUNDE
Die Flugzuversicht der nächsten 24 Stunden, das beste Drei-Stunden-Fenster zum Suchen und die Woche auf einen Blick.

WARUM DIESE VORHERSAGE?
Volle Transparenz: Sieh genau, wie Temperatur, Wind, Luftfeuchte, Wolken, Regen und Luftdruck die heutige Bewertung beeinflusst haben - direkt aus dem Modell.

VON AMEISENHALTERN ANGETRIEBEN
Die Vorhersage ist ein Machine-Learning-Modell, trainiert mit über 10.000 echten Flugmeldungen von Nutzern weltweit. Melde eine Sichtung (oder "Nachgesehen - keine Flüge") und mache sie für alle schlauer.

AUSSERDEM
- Benachrichtigungen nur an erstklassigen Tagen
- Homescreen-Widgets für Android und iPhone
- Live-Karte aktueller Sichtungen in deiner Nähe
- Welche Königinnengröße Saison hat (klein / mittel / groß)
- Dunkelmodus, C/F-Einheiten und 13 Sprachen
- Kostenlos und Open Source. Keine Werbung, kein Tracking.

Von einem Ameisenhalter für Ameisenhalter gemacht - und für alle, die sich je gefragt haben, warum der Himmel plötzlich voller fliegender Ameisen ist.""",
)

L['pl'] = dict(
 title="Prognoza Lotow Mrowek",
 title_native="Prognoza Lotów Mrówek",
 short="Wiedz, kiedy polecą królowe. Prognoza AI trenowana na prawdziwych obserwacjach.",
 subtitle="Kiedy polecą królowe?",
 promo="Nowość: Indeks Lotów Mrówek - czytelne oceny dni, uczciwe szanse i 13 języków. Prognoza trenowana na ponad 10 000 prawdziwych obserwacji z całego świata.",
 keywords="mrowki,mrowka,krolowa,lot,godowy,rojenie,formikarium,kolonia,pogoda,prognoza",
 full="""Czy dziś polecą?

Każda kolonia mrówek czeka na idealny dzień - a potem wypełnia niebo uskrzydlonymi królowymi w locie godowym. Hodowcy mrówek czekają na ten sam dzień. Ta aplikacja mówi, kiedy nadejdzie.

INDEKS LOTÓW MRÓWEK
Zamiast bezsensownego procentu każdy dzień dostaje czytelną ocenę: Brak lotów, Spokojnie, Czujnie, Obiecująco albo Znakomicie - na podstawie porównania dzisiejszej pogody z latami historycznych dni na Twojej szerokości geograficznej i o tej porze roku. Znakomicie oznacza najlepsze ~10% dni sezonu: rzuć wszystko i wyjdź na zewnątrz.

UCZCIWE SZANSE
"Mniej więcej w 1 na 7 takich dni ktoś zgłasza lot." Skalibrowane na tysiącach prawdziwych obserwacji - nigdy wymyślone prawdopodobieństwo.

GODZINA PO GODZINIE
Pewność lotu na najbliższe 24 godziny, najlepsze trzygodzinne okno na obserwacje i cały tydzień w skrócie.

SKĄD TA PROGNOZA?
Pełna przejrzystość: zobacz dokładnie, jak temperatura, wiatr, wilgotność, chmury, deszcz i ciśnienie wpłynęły na dzisiejszą ocenę - prosto z modelu.

NAPĘDZANE PRZEZ HODOWCÓW
Prognoza to model uczenia maszynowego trenowany na ponad 10 000 prawdziwych zgłoszeń lotów od użytkowników z całego świata. Zgłoś obserwację (albo "Sprawdziłem - brak lotów"), a prognoza stanie się mądrzejsza dla wszystkich.

POZA TYM
- Powiadomienia tylko w znakomite dni
- Widżety ekranu głównego na Androida i iPhone'a
- Mapa na żywo z niedawnymi obserwacjami w okolicy
- Który rozmiar królowej ma sezon (mały / średni / duży)
- Tryb ciemny, jednostki C/F i 13 języków
- Za darmo i open source. Bez reklam i śledzenia.

Stworzona przez hodowcę mrówek dla hodowców mrówek - i dla każdego, kto kiedyś zastanawiał się, czemu niebo nagle pełne jest latających mrówek.""",
)

L['cs'] = dict(
 title="Predikce Letu Mravencu",
 title_native="Predikce Letů Mravenců",
 short="Vězte, kdy poletí královny. Predikce AI trénovaná na skutečných pozorováních.",
 subtitle="Kdy poletí královny?",
 promo="Novinka: Index letů mravenců - přehledná hodnocení dní, poctivé šance a 13 jazyků. Trénováno na více než 10 000 skutečných pozorování z celého světa.",
 keywords="mravenci,mravenec,kralovna,svatebni,let,rojeni,formikarium,kolonie,pocasi,predpoved",
 full="""Poletí dnes?

Každá mravenčí kolonie čeká na dokonalý den - a pak naplní oblohu okřídlenými královnami při svatebním letu. Chovatelé mravenců čekají na tentýž den. Tahle aplikace vám řekne, kdy přijde.

INDEX LETŮ MRAVENCŮ
Místo bezvýznamného procenta dostane každý den jasné hodnocení: Bez letů, Klid, Pozor, Nadějné nebo Vynikající - podle toho, jak si dnešní počasí stojí ve srovnání s lety historických dní na vaší zeměpisné šířce a v tomto ročním období. Vynikající znamená nejlepších ~10 % dní sezóny: nechte všeho a jděte ven.

POCTIVÉ ŠANCE
"Zhruba v 1 ze 7 takových dní někdo nahlásí let." Kalibrováno na tisících skutečných pozorování - nikdy vymyšlená pravděpodobnost.

HODINU PO HODINĚ
Důvěra v let na příštích 24 hodin, nejlepší tříhodinové okno na pozorování a celý týden v přehledu.

PROČ TATO PŘEDPOVĚĎ?
Plná transparentnost: podívejte se přesně, jak teplota, vítr, vlhkost, oblačnost, déšť a tlak ovlivnily dnešní hodnocení - přímo z modelu.

POHÁNĚNO CHOVATELI
Předpověď je model strojového učení trénovaný na více než 10 000 skutečných hlášení letů od uživatelů z celého světa. Nahlaste pozorování (nebo "Díval jsem se - žádné lety") a uděláte ji chytřejší pro všechny.

A NAVÍC
- Oznámení jen ve vynikající dny
- Widgety na plochu pro Android i iPhone
- Živá mapa nedávných pozorování ve vašem okolí
- Která velikost královny má sezónu (malá / střední / velká)
- Tmavý režim, jednotky C/F a 13 jazyků
- Zdarma a open source. Bez reklam a sledování.

Vytvořeno chovatelem mravenců pro chovatele mravenců - a pro každého, kdo se kdy divil, proč je obloha najednou plná létajících mravenců.""",
)

L['el'] = dict(
 title="Προβλεψη Πτησης Μυρμηγκιων",
 title_native="Πρόβλεψη Πτήσης Μυρμηγκιών",
 short="Μάθετε πότε θα πετάξουν οι βασίλισσες. Πρόβλεψη ΤΝ από αληθινές παρατηρήσεις.",
 subtitle="Πότε θα πετάξουν οι βασίλισσες",
 promo="Νέο: ο Δείκτης Πτήσεων - καθαρές βαθμολογίες ημέρας, ειλικρινείς πιθανότητες και 13 γλώσσες. Εκπαιδευμένο σε 10.000+ αληθινές παρατηρήσεις από όλο τον κόσμο.",
 keywords="μυρμηγκια,μυρμηγκι,βασιλισσα,γαμηλια,πτηση,ιπταμενα,αποικια,καιρος,προβλεψη",
 full="""Θα πετάξουν σήμερα;

Κάθε αποικία μυρμηγκιών περιμένει την τέλεια μέρα - και μετά γεμίζει τον ουρανό με φτερωτές βασίλισσες στη γαμήλια πτήση τους. Οι εκτροφείς μυρμηγκιών περιμένουν την ίδια μέρα. Αυτή η εφαρμογή σάς λέει πότε έρχεται.

Ο ΔΕΙΚΤΗΣ ΠΤΗΣΕΩΝ
Αντί για ένα ποσοστό χωρίς νόημα, κάθε μέρα παίρνει μια καθαρή βαθμολογία: Καμία πτήση, Ήσυχα, Επιφυλακή, Ελπιδοφόρα ή Κορυφαία - ανάλογα με το πώς συγκρίνεται ο σημερινός καιρός με χρόνια ιστορικών ημερών στο γεωγραφικό σας πλάτος και αυτή την εποχή. Κορυφαία σημαίνει το καλύτερο ~10% των ημερών της σεζόν σας: αφήστε τα όλα και βγείτε έξω.

ΕΙΛΙΚΡΙΝΕΙΣ ΠΙΘΑΝΟΤΗΤΕΣ
«Περίπου 1 στις 7 τέτοιες μέρες αναφέρεται πτήση.» Βαθμονομημένο σε χιλιάδες αληθινές παρατηρήσεις - ποτέ μια επινοημένη πιθανότητα.

ΩΡΑ ΜΕ ΤΗΝ ΩΡΑ
Η εμπιστοσύνη πτήσης για τις επόμενες 24 ώρες, το καλύτερο τρίωρο για ψάξιμο και όλη η εβδομάδα με μια ματιά.

ΓΙΑΤΙ ΑΥΤΗ Η ΠΡΟΒΛΕΨΗ;
Πλήρης διαφάνεια: δείτε ακριβώς πώς θερμοκρασία, άνεμος, υγρασία, σύννεφα, βροχή και πίεση επηρέασαν τη σημερινή βαθμολογία - κατευθείαν από το μοντέλο.

ΜΕ ΤΗ ΔΥΝΑΜΗ ΤΩΝ ΕΚΤΡΟΦΕΩΝ
Η πρόβλεψη είναι ένα μοντέλο μηχανικής μάθησης εκπαιδευμένο σε 10.000+ αληθινές αναφορές πτήσεων από χρήστες παγκοσμίως. Αναφέρετε μια παρατήρηση (ή «Κοίταξα - καμία πτήση») και την κάνετε εξυπνότερη για όλους.

ΕΠΙΣΗΣ
- Ειδοποιήσεις μόνο τις κορυφαίες μέρες
- Widgets αρχικής οθόνης για Android και iPhone
- Ζωντανός χάρτης πρόσφατων παρατηρήσεων κοντά σας
- Ποιο μέγεθος βασίλισσας έχει εποχή (μικρό / μεσαίο / μεγάλο)
- Σκοτεινή λειτουργία, μονάδες C/F και 13 γλώσσες
- Δωρεάν και ανοιχτού κώδικα. Χωρίς διαφημίσεις και παρακολούθηση.

Φτιαγμένο από εκτροφέα μυρμηγκιών, για εκτροφείς μυρμηγκιών - και για όποιον αναρωτήθηκε ποτέ γιατί ο ουρανός γέμισε ξαφνικά ιπτάμενα μυρμήγκια.""",
)

L['pt'] = dict(
 title="Previsor de Voo de Formigas",
 short="Saiba quando as rainhas vão voar. Previsão de IA treinada com relatos reais.",
 subtitle="Quando as rainhas vão voar?",
 promo="Novo: o Índice de Voo - notas claras por dia, chances honestas e 13 idiomas. Treinado com mais de 10.000 relatos reais de criadores do mundo todo.",
 keywords="formigas,formiga,rainha,voo,nupcial,voadoras,formigueiro,colonia,revoada,tempo,previsao",
 full="""Será que voam hoje?

Toda colônia de formigas espera o dia perfeito - e então enche o céu de rainhas aladas no seu voo nupcial. Criadores de formigas esperam o mesmo dia. Este app diz quando ele vem.

O ÍNDICE DE VOO
Em vez de uma porcentagem sem sentido, cada dia recebe uma nota clara: Sem voo, Calmo, Atento, Promissor ou Excelente - conforme o tempo de hoje se compara a anos de dias históricos na sua latitude e época do ano. Excelente significa os ~10% melhores dias da sua estação: largue tudo e vá para fora.

CHANCES HONESTAS
"Cerca de 1 em cada 7 dias como este tem um voo relatado." Calibrado com milhares de relatos reais - nunca uma probabilidade inventada.

HORA A HORA
A confiança de voo das próximas 24 horas, a melhor janela de três horas para procurar e a semana inteira de relance.

POR QUE ESTA PREVISÃO?
Transparência total: veja exatamente como temperatura, vento, umidade, nuvens, chuva e pressão moveram a nota de hoje - direto do modelo.

MOVIDO POR CRIADORES
A previsão é um modelo de aprendizado de máquina treinado com mais de 10.000 relatos reais de voos de usuários do mundo todo. Relate um avistamento (ou "Olhei - sem voos") e você a torna mais inteligente para todos.

TAMBÉM VEM COM
- Notificações só em dias Excelentes
- Widgets de tela inicial para Android e iPhone
- Mapa ao vivo de relatos recentes perto de você
- Qual tamanho de rainha está na estação (pequena / média / grande)
- Modo escuro, unidades C/F e 13 idiomas
- Grátis e código aberto. Sem anúncios, sem rastreamento.

Feito por um criador de formigas, para criadores de formigas - e para qualquer um que já se perguntou por que o céu de repente se encheu de formigas voadoras.""",
)

L['nl'] = dict(
 title="Bruidsvlucht Voorspeller",
 short="Weet wanneer koninginnen vliegen. AI getraind op echte waarnemingen.",
 subtitle="Wanneer vliegen de koninginnen",
 promo="Nieuw: de Mierenvlucht-index - heldere dagscores, eerlijke kansen en 13 talen. Getraind op ruim 10.000 echte waarnemingen van over de hele wereld.",
 keywords="mieren,mier,koningin,bruidsvlucht,vliegende,formicarium,kolonie,zwermen,weer,voorspelling",
 full="""Vliegen ze vandaag?

Elke mierenkolonie wacht op de perfecte dag - en vult dan de lucht met gevleugelde koninginnen tijdens hun bruidsvlucht. Mierenhouders wachten op diezelfde dag. Deze app vertelt je wanneer die komt.

DE MIERENVLUCHT-INDEX
In plaats van een betekenisloos percentage krijgt elke dag een heldere score: Geen vlucht, Rustig, Opletten, Veelbelovend of Uitstekend - op basis van hoe het weer van vandaag zich verhoudt tot jaren aan historische dagen op jouw breedtegraad en in dit seizoen. Uitstekend betekent de beste ~10% van de dagen in jouw seizoen: laat alles vallen en ga naar buiten.

EERLIJKE KANSEN
"Ongeveer 1 op de 7 dagen zoals deze levert een gemelde vlucht op." Gekalibreerd op duizenden echte waarnemingen - nooit een verzonnen kans.

UUR VOOR UUR
Het vluchtvertrouwen voor de komende 24 uur, het beste venster van drie uur om te gaan kijken en de hele week in één oogopslag.

WAAROM DEZE VOORSPELLING?
Volledige transparantie: zie precies hoe temperatuur, wind, luchtvochtigheid, bewolking, regen en luchtdruk de score van vandaag hebben bepaald - rechtstreeks uit het model.

AANGEDREVEN DOOR MIERENHOUDERS
De voorspelling is een machine-learning-model, getraind op ruim 10.000 echte vluchtmeldingen van gebruikers wereldwijd. Meld een waarneming (of "Gekeken - geen vluchten") en je maakt hem slimmer voor iedereen.

VERDER NOG
- Meldingen alleen op uitstekende dagen
- Widgets voor het startscherm van Android en iPhone
- Live kaart met recente waarnemingen bij jou in de buurt
- Welke koninginnenmaat in het seizoen is (klein / middel / groot)
- Donkere modus, C/F-eenheden en 13 talen
- Gratis en open source. Geen advertenties, geen tracking.

Gemaakt door een mierenhouder, voor mierenhouders - en voor iedereen die zich ooit afvroeg waarom de lucht ineens vol vliegende mieren zit.""",
)

L['id'] = dict(
 title="Prediksi Penerbangan Semut",
 short="Tahu kapan ratu semut akan terbang. Prakiraan AI dilatih dari laporan nyata.",
 subtitle="Kapan ratu semut terbang?",
 promo="Baru: Indeks Penerbangan Semut - peringkat harian yang jelas, peluang jujur, dan 13 bahasa. Dilatih dari 10.000+ laporan nyata di seluruh dunia.",
 keywords="semut,ratu,terbang,kawin,laron,koloni,sarang,cuaca,prakiraan",
 full="""Apakah hari ini mereka terbang?

Setiap koloni semut menunggu hari yang sempurna - lalu memenuhi langit dengan ratu bersayap dalam penerbangan kawin mereka. Pemelihara semut menunggu hari yang sama. Aplikasi ini memberi tahu kapan hari itu tiba.

INDEKS PENERBANGAN SEMUT
Alih-alih persentase tanpa makna, setiap hari mendapat peringkat yang jelas: Tidak terbang, Tenang, Waspada, Menjanjikan, atau Prima - berdasarkan perbandingan cuaca hari ini dengan bertahun-tahun data historis di lintang dan musim Anda. Prima berarti ~10% hari terbaik di musim Anda: tinggalkan semuanya dan keluarlah.

PELUANG YANG JUJUR
"Sekitar 1 dari 7 hari seperti ini ada penerbangan yang dilaporkan." Dikalibrasi dengan ribuan laporan nyata - bukan probabilitas karangan.

JAM DEMI JAM
Keyakinan penerbangan 24 jam ke depan, jendela tiga jam terbaik untuk mencari, dan sepekan dalam sekali pandang.

KENAPA PRAKIRAAN INI?
Transparansi penuh: lihat persis bagaimana suhu, angin, kelembapan, awan, hujan, dan tekanan menggerakkan peringkat hari ini - langsung dari model.

DIGERAKKAN PEMELIHARA SEMUT
Prakiraan ini adalah model machine learning yang dilatih dari 10.000+ laporan penerbangan nyata pengguna di seluruh dunia. Laporkan penampakan (atau "Sudah melihat - tidak ada") dan Anda membuatnya lebih pintar untuk semua.

SELAIN ITU
- Notifikasi hanya pada hari Prima
- Widget layar utama untuk Android dan iPhone
- Peta langsung laporan terbaru di sekitar Anda
- Ukuran ratu mana yang sedang musim (kecil / sedang / besar)
- Mode gelap, satuan C/F, dan 13 bahasa
- Gratis dan open source. Tanpa iklan, tanpa pelacakan.

Dibuat oleh pemelihara semut, untuk pemelihara semut - dan untuk siapa pun yang pernah bertanya-tanya kenapa langit tiba-tiba penuh semut terbang.""",
)

L['ms'] = dict(
 title="Peramal Penerbangan Semut",
 short="Tahu bila permaisuri akan terbang. AI dilatih daripada laporan sebenar.",
 subtitle="Bila permaisuri akan terbang?",
 promo="Baharu: Indeks Penerbangan Semut - penarafan harian yang jelas, peluang jujur dan 13 bahasa. Dilatih daripada 10,000+ laporan sebenar seluruh dunia.",
 keywords="semut,permaisuri,terbang,kahwin,kelkatu,koloni,sarang,cuaca,ramalan",
 full="""Adakah mereka terbang hari ini?

Setiap koloni semut menunggu hari yang sempurna - lalu memenuhi langit dengan permaisuri bersayap dalam penerbangan kahwin mereka. Pemelihara semut menunggu hari yang sama. Aplikasi ini memberitahu bila hari itu tiba.

INDEKS PENERBANGAN SEMUT
Bukan peratusan tanpa makna, setiap hari mendapat penarafan jelas: Tiada penerbangan, Tenang, Berjaga-jaga, Menjanjikan atau Terbaik - berdasarkan perbandingan cuaca hari ini dengan bertahun-tahun data lampau di latitud dan musim anda. Terbaik bermakna ~10% hari terbaik musim anda: tinggalkan semuanya dan keluarlah.

PELUANG YANG JUJUR
"Kira-kira 1 daripada 7 hari seperti ini ada penerbangan dilaporkan." Ditentukur dengan ribuan laporan sebenar - bukan kebarangkalian rekaan.

JAM DEMI JAM
Keyakinan penerbangan 24 jam akan datang, tetingkap tiga jam terbaik untuk mencari, dan seminggu dalam satu pandangan.

KENAPA RAMALAN INI?
Ketelusan penuh: lihat dengan tepat bagaimana suhu, angin, kelembapan, awan, hujan dan tekanan menggerakkan penarafan hari ini - terus daripada model.

DIKUASAKAN PEMELIHARA SEMUT
Ramalan ini ialah model pembelajaran mesin yang dilatih daripada 10,000+ laporan penerbangan sebenar pengguna seluruh dunia. Laporkan penampakan (atau "Sudah lihat - tiada penerbangan") dan anda menjadikannya lebih pintar untuk semua.

SELAIN ITU
- Pemberitahuan hanya pada hari Terbaik
- Widget skrin utama untuk Android dan iPhone
- Peta langsung laporan terkini berdekatan anda
- Saiz permaisuri yang bermusim (kecil / sederhana / besar)
- Mod gelap, unit C/F dan 13 bahasa
- Percuma dan sumber terbuka. Tiada iklan, tiada penjejakan.

Dibuat oleh pemelihara semut, untuk pemelihara semut - dan untuk sesiapa yang pernah tertanya-tanya kenapa langit tiba-tiba dipenuhi semut terbang.""",
)

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text.strip() + '\n')

problems = []
for key, (play_loc, ios_loc) in LOCALE_MAP.items():
    d = L[key]
    title = d.get('title_native', d['title'])
    if len(title) > 30: problems.append(f"{key} title {len(title)}")
    if len(d['short']) > 80: problems.append(f"{key} short {len(d['short'])}")
    if len(d['full']) > 4000: problems.append(f"{key} full {len(d['full'])}")
    if len(d['subtitle']) > 30: problems.append(f"{key} subtitle {len(d['subtitle'])}")
    if len(d['promo']) > 170: problems.append(f"{key} promo {len(d['promo'])}")
    if len(d['keywords']) > 100: problems.append(f"{key} keywords {len(d['keywords'])}")

    base = os.path.join(REPO, 'store', 'listings', 'play', play_loc)
    write(os.path.join(base, 'title.txt'), title)
    write(os.path.join(base, 'short_description.txt'), d['short'])
    write(os.path.join(base, 'full_description.txt'), d['full'])

    if ios_loc:
        base = os.path.join(REPO, 'store', 'listings', 'ios', ios_loc)
        write(os.path.join(base, 'name.txt'), 'Ant Nuptial Flight Predictor')
        write(os.path.join(base, 'subtitle.txt'), d['subtitle'])
        write(os.path.join(base, 'promotional_text.txt'), d['promo'])
        write(os.path.join(base, 'description.txt'), d['full'])
        write(os.path.join(base, 'keywords.txt'), d['keywords'])

if problems:
    print('LIMIT VIOLATIONS:', problems)
else:
    print('all limits OK;', len(LOCALE_MAP), 'play locales,',
          sum(1 for _, i in LOCALE_MAP.values() if i), 'ios locales')

import 'package:flutter/widgets.dart';

enum GroceryCategory {
  produce,
  meatPoultry,
  seafood,
  dairyEggs,
  bakeryGrains,
  pantry,
  frozen,
  beverages,
  herbsSpices,
  other,
}

String _localeKey(Locale locale) {
  if (locale.languageCode != 'zh') return locale.languageCode;
  if (locale.scriptCode == 'Hant' ||
      const {'TW', 'HK', 'MO'}.contains(locale.countryCode)) {
    return 'zh_Hant';
  }
  return 'zh_Hans';
}

extension GroceryCategoryLabel on GroceryCategory {
  String label(Locale locale) {
    final key = _localeKey(locale);
    return _categoryLabels[this]?[key] ?? _categoryLabels[this]!['en']!;
  }
}

class GroceryItem {
  const GroceryItem(this.id, this.category, this.names, {this.aliases = const <String>[]});
  final String id;
  final GroceryCategory category;
  final Map<String, String> names;
  final List<String> aliases;

  String display(Locale locale) => names[_localeKey(locale)] ?? names['en']!;

  bool matches(String query, Locale locale) {
    final normalized = _fold(query.trim());
    if (normalized.isEmpty) return true;
    return <String>[...names.values, ...aliases]
        .any((name) => _fold(name).contains(normalized));
  }
}

String _fold(String value) {
  var out = value.toLowerCase();
  const groups = <String, String>{
    'áàâäãåāăą': 'a', 'çćč': 'c', 'ďđ': 'd', 'éèêëēėęě': 'e',
    'íìîïīį': 'i', 'ł': 'l', 'ñńň': 'n', 'óòôöõøōő': 'o',
    'řŕ': 'r', 'śšş': 's', 'ťţ': 't', 'úùûüūůű': 'u',
    'ýÿ': 'y', 'žźż': 'z', 'œ': 'o', 'æ': 'a',
  };
  for (final entry in groups.entries) {
    for (final rune in entry.key.runes) {
      out = out.replaceAll(String.fromCharCode(rune), entry.value);
    }
  }
  return out.replaceAll(RegExp(r'[\s\-_/.,()]+'), ' ').trim();
}

const _categoryLabels = <GroceryCategory, Map<String, String>>{
  GroceryCategory.produce: {'en':'Produce','es':'Frutas y verduras','pt':'Hortifruti','fr':'Fruits et légumes','de':'Obst & Gemüse','it':'Frutta e verdura','ar':'خضار وفواكه','ja':'青果','ko':'농산물','zh_Hans':'果蔬','zh_Hant':'蔬果'},
  GroceryCategory.meatPoultry: {'en':'Meat & Poultry','es':'Carne y aves','pt':'Carnes e aves','fr':'Viandes et volaille','de':'Fleisch & Geflügel','it':'Carne e pollame','ar':'لحوم ودواجن','ja':'肉・鶏肉','ko':'육류·가금류','zh_Hans':'肉类和禽类','zh_Hant':'肉類和家禽'},
  GroceryCategory.seafood: {'en':'Seafood','es':'Pescado y marisco','pt':'Peixes e mariscos','fr':'Poissons et fruits de mer','de':'Fisch & Meeresfrüchte','it':'Pesce e frutti di mare','ar':'أسماك ومأكولات بحرية','ja':'魚介類','ko':'해산물','zh_Hans':'海鲜','zh_Hant':'海鮮'},
  GroceryCategory.dairyEggs: {'en':'Dairy & Eggs','es':'Lácteos y huevos','pt':'Laticínios e ovos','fr':'Produits laitiers et œufs','de':'Milchprodukte & Eier','it':'Latticini e uova','ar':'ألبان وبيض','ja':'乳製品・卵','ko':'유제품·달걀','zh_Hans':'乳制品和鸡蛋','zh_Hant':'乳製品和雞蛋'},
  GroceryCategory.bakeryGrains: {'en':'Bakery & Grains','es':'Pan y cereales','pt':'Padaria e grãos','fr':'Boulangerie et céréales','de':'Backwaren & Getreide','it':'Forno e cereali','ar':'مخبوزات وحبوب','ja':'パン・穀類','ko':'빵·곡물','zh_Hans':'烘焙和谷物','zh_Hant':'烘焙和穀物'},
  GroceryCategory.pantry: {'en':'Pantry','es':'Despensa','pt':'Despensa','fr':'Épicerie','de':'Vorrat','it':'Dispensa','ar':'المؤن','ja':'常備食品','ko':'식료품 저장','zh_Hans':'食品储藏','zh_Hant':'食品儲藏'},
  GroceryCategory.frozen: {'en':'Frozen','es':'Congelados','pt':'Congelados','fr':'Surgelés','de':'Tiefkühl','it':'Surgelati','ar':'مجمدات','ja':'冷凍食品','ko':'냉동식품','zh_Hans':'冷冻','zh_Hant':'冷凍'},
  GroceryCategory.beverages: {'en':'Beverages','es':'Bebidas','pt':'Bebidas','fr':'Boissons','de':'Getränke','it':'Bevande','ar':'مشروبات','ja':'飲料','ko':'음료','zh_Hans':'饮料','zh_Hant':'飲料'},
  GroceryCategory.herbsSpices: {'en':'Herbs & Spices','es':'Hierbas y especias','pt':'Ervas e especiarias','fr':'Herbes et épices','de':'Kräuter & Gewürze','it':'Erbe e spezie','ar':'أعشاب وتوابل','ja':'ハーブ・香辛料','ko':'허브·향신료','zh_Hans':'香草和香料','zh_Hant':'香草和香料'},
  GroceryCategory.other: {'en':'Other','es':'Otros','pt':'Outros','fr':'Autres','de':'Sonstiges','it':'Altro','ar':'أخرى','ja':'その他','ko':'기타','zh_Hans':'其他','zh_Hant':'其他'},
};

const kitchenCatalogue = <GroceryItem>[
  GroceryItem('onion', GroceryCategory.produce, {'en':'Onion','es':'Cebolla','pt':'Cebola','fr':'Oignon','de':'Zwiebel','it':'Cipolla','ar':'بصل','ja':'玉ねぎ','ko':'양파','zh_Hans':'洋葱','zh_Hant':'洋蔥'}),
  GroceryItem('garlic', GroceryCategory.produce, {'en':'Garlic','es':'Ajo','pt':'Alho','fr':'Ail','de':'Knoblauch','it':'Aglio','ar':'ثوم','ja':'にんにく','ko':'마늘','zh_Hans':'大蒜','zh_Hant':'大蒜'}),
  GroceryItem('tomato', GroceryCategory.produce, {'en':'Tomato','es':'Tomate','pt':'Tomate','fr':'Tomate','de':'Tomate','it':'Pomodoro','ar':'طماطم','ja':'トマト','ko':'토마토','zh_Hans':'番茄','zh_Hant':'番茄'}),
  GroceryItem('potato', GroceryCategory.produce, {'en':'Potato','es':'Patata','pt':'Batata','fr':'Pomme de terre','de':'Kartoffel','it':'Patata','ar':'بطاطس','ja':'じゃがいも','ko':'감자','zh_Hans':'土豆','zh_Hant':'馬鈴薯'}),
  GroceryItem('carrot', GroceryCategory.produce, {'en':'Carrot','es':'Zanahoria','pt':'Cenoura','fr':'Carotte','de':'Karotte','it':'Carota','ar':'جزر','ja':'にんじん','ko':'당근','zh_Hans':'胡萝卜','zh_Hant':'胡蘿蔔'}),
  GroceryItem('bell_pepper', GroceryCategory.produce, {'en':'Bell pepper','es':'Pimiento','pt':'Pimentão','fr':'Poivron','de':'Paprika','it':'Peperone','ar':'فلفل حلو','ja':'パプリカ','ko':'피망','zh_Hans':'甜椒','zh_Hant':'甜椒'}),
  GroceryItem('lettuce', GroceryCategory.produce, {'en':'Lettuce','es':'Lechuga','pt':'Alface','fr':'Laitue','de':'Salat','it':'Lattuga','ar':'خس','ja':'レタス','ko':'상추','zh_Hans':'生菜','zh_Hant':'生菜'}),
  GroceryItem('spinach', GroceryCategory.produce, {'en':'Spinach','es':'Espinaca','pt':'Espinafre','fr':'Épinards','de':'Spinat','it':'Spinaci','ar':'سبانخ','ja':'ほうれん草','ko':'시금치','zh_Hans':'菠菜','zh_Hant':'菠菜'}),
  GroceryItem('cabbage', GroceryCategory.produce, {'en':'Cabbage','es':'Repollo','pt':'Repolho','fr':'Chou','de':'Kohl','it':'Cavolo','ar':'ملفوف','ja':'キャベツ','ko':'양배추','zh_Hans':'卷心菜','zh_Hant':'高麗菜'}),
  GroceryItem('broccoli', GroceryCategory.produce, {'en':'Broccoli','es':'Brócoli','pt':'Brócolis','fr':'Brocoli','de':'Brokkoli','it':'Broccoli','ar':'بروكلي','ja':'ブロッコリー','ko':'브로콜리','zh_Hans':'西兰花','zh_Hant':'花椰菜'}),
  GroceryItem('cucumber', GroceryCategory.produce, {'en':'Cucumber','es':'Pepino','pt':'Pepino','fr':'Concombre','de':'Gurke','it':'Cetriolo','ar':'خيار','ja':'きゅうり','ko':'오이','zh_Hans':'黄瓜','zh_Hant':'小黃瓜'}),
  GroceryItem('lemon', GroceryCategory.produce, {'en':'Lemon','es':'Limón','pt':'Limão','fr':'Citron','de':'Zitrone','it':'Limone','ar':'ليمون','ja':'レモン','ko':'레몬','zh_Hans':'柠檬','zh_Hant':'檸檬'}),
  GroceryItem('avocado', GroceryCategory.produce, {'en':'Avocado','es':'Aguacate','pt':'Abacate','fr':'Avocat','de':'Avocado','it':'Avocado','ar':'أفوكادو','ja':'アボカド','ko':'아보카도','zh_Hans':'牛油果','zh_Hant':'酪梨'}),
  GroceryItem('mushroom', GroceryCategory.produce, {'en':'Mushroom','es':'Champiñón','pt':'Cogumelo','fr':'Champignon','de':'Pilz','it':'Fungo','ar':'فطر','ja':'きのこ','ko':'버섯','zh_Hans':'蘑菇','zh_Hant':'蘑菇'}),
  GroceryItem('chicken_breast', GroceryCategory.meatPoultry, {'en':'Chicken breast','es':'Pechuga de pollo','pt':'Peito de frango','fr':'Blanc de poulet','de':'Hähnchenbrust','it':'Petto di pollo','ar':'صدر دجاج','ja':'鶏むね肉','ko':'닭가슴살','zh_Hans':'鸡胸肉','zh_Hant':'雞胸肉'}),
  GroceryItem('beef', GroceryCategory.meatPoultry, {'en':'Beef','es':'Carne de res','pt':'Carne bovina','fr':'Bœuf','de':'Rindfleisch','it':'Manzo','ar':'لحم بقري','ja':'牛肉','ko':'소고기','zh_Hans':'牛肉','zh_Hant':'牛肉'}),
  GroceryItem('ground_beef', GroceryCategory.meatPoultry, {'en':'Ground beef','es':'Carne molida','pt':'Carne moída','fr':'Bœuf haché','de':'Rinderhackfleisch','it':'Manzo macinato','ar':'لحم بقري مفروم','ja':'牛ひき肉','ko':'다진 소고기','zh_Hans':'牛肉末','zh_Hant':'牛絞肉'}),
  GroceryItem('pork', GroceryCategory.meatPoultry, {'en':'Pork','es':'Cerdo','pt':'Carne de porco','fr':'Porc','de':'Schweinefleisch','it':'Maiale','ar':'لحم خنزير','ja':'豚肉','ko':'돼지고기','zh_Hans':'猪肉','zh_Hant':'豬肉'}),
  GroceryItem('lamb', GroceryCategory.meatPoultry, {'en':'Lamb','es':'Cordero','pt':'Cordeiro','fr':'Agneau','de':'Lamm','it':'Agnello','ar':'لحم ضأن','ja':'ラム肉','ko':'양고기','zh_Hans':'羊肉','zh_Hant':'羊肉'}),
  GroceryItem('salmon', GroceryCategory.seafood, {'en':'Salmon','es':'Salmón','pt':'Salmão','fr':'Saumon','de':'Lachs','it':'Salmone','ar':'سلمون','ja':'サーモン','ko':'연어','zh_Hans':'三文鱼','zh_Hant':'鮭魚'}),
  GroceryItem('tuna', GroceryCategory.seafood, {'en':'Tuna','es':'Atún','pt':'Atum','fr':'Thon','de':'Thunfisch','it':'Tonno','ar':'تونة','ja':'まぐろ','ko':'참치','zh_Hans':'金枪鱼','zh_Hant':'鮪魚'}),
  GroceryItem('shrimp', GroceryCategory.seafood, {'en':'Shrimp','es':'Camarón','pt':'Camarão','fr':'Crevettes','de':'Garnelen','it':'Gamberi','ar':'روبيان','ja':'えび','ko':'새우','zh_Hans':'虾','zh_Hant':'蝦'}),
  GroceryItem('eggs', GroceryCategory.dairyEggs, {'en':'Eggs','es':'Huevos','pt':'Ovos','fr':'Œufs','de':'Eier','it':'Uova','ar':'بيض','ja':'卵','ko':'달걀','zh_Hans':'鸡蛋','zh_Hant':'雞蛋'}),
  GroceryItem('milk', GroceryCategory.dairyEggs, {'en':'Milk','es':'Leche','pt':'Leite','fr':'Lait','de':'Milch','it':'Latte','ar':'حليب','ja':'牛乳','ko':'우유','zh_Hans':'牛奶','zh_Hant':'牛奶'}),
  GroceryItem('butter', GroceryCategory.dairyEggs, {'en':'Butter','es':'Mantequilla','pt':'Manteiga','fr':'Beurre','de':'Butter','it':'Burro','ar':'زبدة','ja':'バター','ko':'버터','zh_Hans':'黄油','zh_Hant':'奶油'}),
  GroceryItem('cheese', GroceryCategory.dairyEggs, {'en':'Cheese','es':'Queso','pt':'Queijo','fr':'Fromage','de':'Käse','it':'Formaggio','ar':'جبن','ja':'チーズ','ko':'치즈','zh_Hans':'奶酪','zh_Hant':'起司'}),
  GroceryItem('yogurt', GroceryCategory.dairyEggs, {'en':'Yogurt','es':'Yogur','pt':'Iogurte','fr':'Yaourt','de':'Joghurt','it':'Yogurt','ar':'زبادي','ja':'ヨーグルト','ko':'요거트','zh_Hans':'酸奶','zh_Hant':'優格'}),
  GroceryItem('rice', GroceryCategory.bakeryGrains, {'en':'Rice','es':'Arroz','pt':'Arroz','fr':'Riz','de':'Reis','it':'Riso','ar':'أرز','ja':'米','ko':'쌀','zh_Hans':'米','zh_Hant':'米'}),
  GroceryItem('pasta', GroceryCategory.bakeryGrains, {'en':'Pasta','es':'Pasta','pt':'Massa','fr':'Pâtes','de':'Nudeln','it':'Pasta','ar':'معكرونة','ja':'パスタ','ko':'파스타','zh_Hans':'意大利面','zh_Hant':'義大利麵'}),
  GroceryItem('bread', GroceryCategory.bakeryGrains, {'en':'Bread','es':'Pan','pt':'Pão','fr':'Pain','de':'Brot','it':'Pane','ar':'خبز','ja':'パン','ko':'빵','zh_Hans':'面包','zh_Hant':'麵包'}),
  GroceryItem('flour', GroceryCategory.bakeryGrains, {'en':'Flour','es':'Harina','pt':'Farinha','fr':'Farine','de':'Mehl','it':'Farina','ar':'دقيق','ja':'小麦粉','ko':'밀가루','zh_Hans':'面粉','zh_Hant':'麵粉'}),
  GroceryItem('beans', GroceryCategory.pantry, {'en':'Beans','es':'Frijoles','pt':'Feijão','fr':'Haricots','de':'Bohnen','it':'Fagioli','ar':'فاصوليا','ja':'豆','ko':'콩','zh_Hans':'豆类','zh_Hant':'豆類'}),
  GroceryItem('lentils', GroceryCategory.pantry, {'en':'Lentils','es':'Lentejas','pt':'Lentilhas','fr':'Lentilles','de':'Linsen','it':'Lenticchie','ar':'عدس','ja':'レンズ豆','ko':'렌틸콩','zh_Hans':'扁豆','zh_Hant':'扁豆'}),
  GroceryItem('chickpeas', GroceryCategory.pantry, {'en':'Chickpeas','es':'Garbanzos','pt':'Grão-de-bico','fr':'Pois chiches','de':'Kichererbsen','it':'Ceci','ar':'حمص','ja':'ひよこ豆','ko':'병아리콩','zh_Hans':'鹰嘴豆','zh_Hant':'鷹嘴豆'}),
  GroceryItem('olive_oil', GroceryCategory.pantry, {'en':'Olive oil','es':'Aceite de oliva','pt':'Azeite','fr':'Huile d’olive','de':'Olivenöl','it':'Olio d’oliva','ar':'زيت زيتون','ja':'オリーブオイル','ko':'올리브유','zh_Hans':'橄榄油','zh_Hant':'橄欖油'}),
  GroceryItem('salt', GroceryCategory.herbsSpices, {'en':'Salt','es':'Sal','pt':'Sal','fr':'Sel','de':'Salz','it':'Sale','ar':'ملح','ja':'塩','ko':'소금','zh_Hans':'盐','zh_Hant':'鹽'}),
  GroceryItem('black_pepper', GroceryCategory.herbsSpices, {'en':'Black pepper','es':'Pimienta negra','pt':'Pimenta-do-reino','fr':'Poivre noir','de':'Schwarzer Pfeffer','it':'Pepe nero','ar':'فلفل أسود','ja':'黒こしょう','ko':'후추','zh_Hans':'黑胡椒','zh_Hant':'黑胡椒'}),
  GroceryItem('cumin', GroceryCategory.herbsSpices, {'en':'Cumin','es':'Comino','pt':'Cominho','fr':'Cumin','de':'Kreuzkümmel','it':'Cumino','ar':'كمون','ja':'クミン','ko':'커민','zh_Hans':'孜然','zh_Hant':'孜然'}),
  GroceryItem('paprika', GroceryCategory.herbsSpices, {'en':'Paprika','es':'Pimentón','pt':'Páprica','fr':'Paprika','de':'Paprikapulver','it':'Paprika','ar':'بابريكا','ja':'パプリカパウダー','ko':'파프리카 가루','zh_Hans':'红椒粉','zh_Hant':'紅椒粉'}),
  GroceryItem('cilantro', GroceryCategory.herbsSpices, {'en':'Cilantro / coriander','es':'Cilantro','pt':'Coentro','fr':'Coriandre','de':'Koriander','it':'Coriandolo','ar':'كزبرة','ja':'パクチー','ko':'고수','zh_Hans':'香菜','zh_Hant':'香菜'}),
  GroceryItem('parsley', GroceryCategory.herbsSpices, {'en':'Parsley','es':'Perejil','pt':'Salsa','fr':'Persil','de':'Petersilie','it':'Prezzemolo','ar':'بقدونس','ja':'パセリ','ko':'파슬리','zh_Hans':'欧芹','zh_Hant':'巴西里'}),

  GroceryItem('frozen_vegetables', GroceryCategory.frozen, {'en':'Frozen vegetables','es':'Verduras congeladas','pt':'Legumes congelados','fr':'Légumes surgelés','de':'Tiefkühlgemüse','it':'Verdure surgelate','ar':'خضروات مجمدة','ja':'冷凍野菜','ko':'냉동 채소','zh_Hans':'冷冻蔬菜','zh_Hant':'冷凍蔬菜'}),
  GroceryItem('frozen_fruit', GroceryCategory.frozen, {'en':'Frozen fruit','es':'Fruta congelada','pt':'Fruta congelada','fr':'Fruits surgelés','de':'Tiefkühlobst','it':'Frutta surgelata','ar':'فاكهة مجمدة','ja':'冷凍フルーツ','ko':'냉동 과일','zh_Hans':'冷冻水果','zh_Hant':'冷凍水果'}),
  GroceryItem('ice', GroceryCategory.frozen, {'en':'Ice','es':'Hielo','pt':'Gelo','fr':'Glaçons','de':'Eiswürfel','it':'Ghiaccio','ar':'ثلج','ja':'氷','ko':'얼음','zh_Hans':'冰块','zh_Hant':'冰塊'}),
  GroceryItem('water', GroceryCategory.beverages, {'en':'Water','es':'Agua','pt':'Água','fr':'Eau','de':'Wasser','it':'Acqua','ar':'ماء','ja':'水','ko':'물','zh_Hans':'水','zh_Hant':'水'}),
  GroceryItem('coffee', GroceryCategory.beverages, {'en':'Coffee','es':'Café','pt':'Café','fr':'Café','de':'Kaffee','it':'Caffè','ar':'قهوة','ja':'コーヒー','ko':'커피','zh_Hans':'咖啡','zh_Hant':'咖啡'}),
  GroceryItem('tea', GroceryCategory.beverages, {'en':'Tea','es':'Té','pt':'Chá','fr':'Thé','de':'Tee','it':'Tè','ar':'شاي','ja':'お茶','ko':'차','zh_Hans':'茶','zh_Hant':'茶'}),
  GroceryItem('juice', GroceryCategory.beverages, {'en':'Juice','es':'Zumo / jugo','pt':'Sumo / suco','fr':'Jus','de':'Saft','it':'Succo','ar':'عصير','ja':'ジュース','ko':'주스','zh_Hans':'果汁','zh_Hant':'果汁'}, aliases: ['fruit juice']),
  GroceryItem('tofu', GroceryCategory.other, {'en':'Tofu','es':'Tofu','pt':'Tofu','fr':'Tofu','de':'Tofu','it':'Tofu','ar':'توفو','ja':'豆腐','ko':'두부','zh_Hans':'豆腐','zh_Hant':'豆腐'}),
];

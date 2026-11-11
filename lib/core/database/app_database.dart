import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db); // constructeur privé : on passe par open()

  final Database db;

  static const _fileName = 'lexika.db';
  static const _version = 1; // à incrémenter à chaque changement de schéma

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    bool seed = true,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await getDatabasesPath(), _fileName);

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        // SQLite n'applique les clés étrangères que si on le demande.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _createSchema(db);
          if (seed) await _seedStarterDeck(db);
        },
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE decks (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        color      INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id    INTEGER NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        front      TEXT    NOT NULL,
        back       TEXT    NOT NULL,
        box        INTEGER NOT NULL DEFAULT 1,
        due_at     INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE reviews (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id     INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        knew        INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_cards_due ON cards(deck_id, due_at)');
  }

  /// Un premier paquet pour que l'app ne soit pas vide au lancement.
  static Future<void> _seedStarterDeck(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deckId = await db.insert('decks', {
      'name': 'Capitales du monde',
      'color': 0xFF2E7D6B,
      'created_at': now,
    });

    const cards = [
      ('Kenya', 'Nairobi'),
      ('Canada', 'Ottawa'),
      ('Australie', 'Canberra'),
      ('Maroc', 'Rabat'),
      ('Brésil', 'Brasília'),
      ('Nouvelle-Zélande', 'Wellington'),
      ('Madagascar', 'Antananarivo'),
      ('Vietnam', 'Hanoï'),
    ];

    final batch = db
        .batch(); // une seule transaction pour toutes les insertions
    for (final (country, capital) in cards) {
      batch.insert('cards', {
        'deck_id': deckId,
        'front': 'Capitale : $country',
        'back': capital,
        'box': 1,
        'due_at': now,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Exemple pour une future version 2 :
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE cards ADD COLUMN hint TEXT');
    // }
  }
}

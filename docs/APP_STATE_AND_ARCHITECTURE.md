# PinTok — Güncel Uygulama Durumu ve Mimari (AI Bağlam Dokümanı)

Bu doküman, PinTok Flutter uygulamasının **şu anki** ne yaptığını, nasıl yaptığını ve hangi teknolojilerle yaptığını özetler. Başka bir AI’a bağlam vermek için kullanılabilir.

---

## 1. Proje Özeti

**PinTok**, seyahat / yer işaretleme (pin) odaklı bir mobil uygulamadır. Kullanıcılar:
- Fotoğraf yükleyip **AI (Gemini)** ile yer bilgisi çıkarır,
- Bu yerleri **harita** üzerinde görür ve **koleksiyonlara** kaydeder,
- **Koleksiyonlar** (journey’ler) oluşturup içlerine **pin** ekler.

Backend: **Supabase** (Auth, Postgres, RLS). Görsel analiz: **Google Gemini API**.

---

## 2. Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Framework | Flutter (Dart 3.8+) |
| State | Provider (`provider` paketi) |
| Backend / Auth / DB | Supabase (supabase_flutter) |
| Harita | flutter_map, latlong2, flutter_map_animations |
| AI (görsel analiz) | Google Generative AI (google_generative_ai), HTTP ile Gemini API |
| Görsel seçimi | image_picker |
| UI | Material, google_fonts, flutter_animate, lucide_icons_flutter |
| Yerel tercihler | shared_preferences |

Supabase projesi: `irbmniebwetgwiflnvpg.supabase.co` (anon key main.dart içinde).  
Gemini API anahtarı: `--dart-define=GEMINI_API_KEY=...` ile verilir.

---

## 3. Uygulama Akışı (Navigation)

```
main.dart
  └── PinTokApp (MultiProvider: SavedPlacesProvider, SettingsProvider)
        └── _AppHome (state: _showOnboarding, _showAuth, _showLanding, _hasSession)
              ├── [1] LandingView          ← İlk açılış: "Get Started"
              ├── [2] OnboardingView       ← Onboarding tamamlanmamışsa
              ├── [3] AuthView             ← Oturum yoksa (Sign In / Sign Up)
              └── [4] MainShell            ← Oturum varsa ana uygulama
```

- **Onboarding** tamamlanmış mı: `shared_preferences` ile saklanır (`isOnboardingCompleted()`).
- **Oturum**: `Supabase.instance.client.auth.currentSession != null`.
- Geçişler: `AnimatedSwitcher` ile fade/scale.

---

## 4. Ana Kabuk: MainShell

**Dosya:** `lib/screens/main_shell.dart`

- **Alt navigasyon:** 3 öğe (floating pill bar):
  - **Sol:** Harita (Map) — index 0
  - **Orta:** AI Nucleus — overlay açar (fotoğraf tarama)
  - **Sağ:** Kullanıcı ikonu — index 1, **Library** ekranına gider (ekranda “Profile”/“My Journey” olarak düşünülebilir)

Gösterilen sayfalar:
- **Index 0:** `_MapExplorerTab` → `MapScreen` (harita + kullanıcı pin’leri + Supabase’ten koleksiyon pin’leri)
- **Index 1:** `LibraryView` (koleksiyonlar grid’i, profil başlığı, ayarlar, “Create journey”)

**Önemli state (MainShell):**
- `_currentIndex`: 0 = Map, 1 = Library
- `_previewSpot`, `_previewLocation`, `_previewImageBytes`: AI’dan dönen “önizleme” pin’i (henüz koleksiyona kaydedilmedi)
- `_showAiOverlay`: Orta butona basılınca açılan overlay (fotoğraf tarama / link girişi)
- `_focusLocationForMap`: Saved Places’ten haritada odaklanılacak konum

**Kullanıcı pin’leri:** `SavedPlacesProvider` (Provider) ile tutulur; `MapScreen`’e `userPinnedLocations` olarak verilir. Pin “Save to collection” ile Supabase’e de yazılır (aşağıda).

---

## 5. Harita (MapScreen)

**Dosya:** `lib/screens/map_screen.dart`

- **Harita:** FlutterMap, CartoDB Dark Matter tile’ları, koyu tema.
- **Marker’lar:**
  1. **Preview pin:** AI’dan yeni taranan yer; “ghost” marker, kaydedilince kalkar.
  2. **Kullanıcı pin’leri:** `userPinnedLocations` (SavedPlacesProvider’dan); tıklanınca haritada odaklanır.
  3. **Supabase pin’leri:** `SupabaseService().getPins(collectionId)` ile; koleksiyon filtresi üstte chip’lerle (All Pins / koleksiyon adları).
- **Explore sheet:** Eski “Featured pins” mock’u kaldırıldı; artık boş (`SizedBox.shrink()`).

**Preview (AI’dan gelen pin) akışı:**
- “Found it!” kartında “Add to map” → `_SaveToCollectionSheet` açılır → Koleksiyon seçilir → `SupabaseService().savePin(pin)` çağrılır, `PinModel.forInsert(...)` ile pin oluşturulur.
- Ardından `onConfirmPreview(selectedCollection)` çağrılır: MainShell hem `SavedPlacesProvider.add(SavedPlace(...))` yapar hem preview state’i temizler.

Yani bir pin hem **yerel** (SavedPlacesProvider) hem **sunucu** (Supabase `pins` tablosu) tarafında tutulur.

---

## 6. AI Akışı (Fotoğraf → Pin)

**Dosya:** `lib/services/ai_service.dart`, `lib/widgets/analysis_overlay.dart`, `lib/screens/main_shell.dart`

1. Kullanıcı **AI Nucleus**’a (orta buton) basar → `_AiInputOverlay` açılır (fotoğraf tarama / link).
2. “Scan photo” → `ImagePicker().pickImage()` → `AiService().analyzeImage(xFile)`.
3. **AiService:** Gemini API’ye (HTTP / google_generative_ai) görsel + sistem prompt gönderir. Cevaptan JSON parse edilir → `AnalyzedSpot` (name, city, description, category).
4. Ardından **geocoding** (şu an mock veya harici servis) ile `MockLocation` (lat, lng, name, city) üretilir.
5. `AnalysisOverlayScreen` sonucu gösterir; kullanıcı “Found it!” derse `onPreviewReady(spot, location, imageBytes)` çağrılır.
6. MainShell’de `_setPreview(spot, location, bytes)` ile preview state set edilir, tab Map’e geçer; haritada ghost pin + “Found it!” kartı görünür.
7. “Add to map” → koleksiyon seçimi → Supabase’e pin kaydı + provider’a SavedPlace ekleme (yukarıda).

**Modeller:** `AnalyzedSpot` (AI çıktısı), `MockLocation` (harita/pin konumu; id, name, city, lat, lng, imageUrl, thumbnailColor).

---

## 7. Koleksiyonlar ve Pin Verisi (Supabase)

**Servis:** `lib/services/supabase_service.dart`

- **Collections:** `getCollections()`, `createCollection(name, {description})` — `collections` tablosu, `user_id` ile RLS.
- **Pins:** `getPins(collectionId?)`, `savePin(PinModel)` — `pins` tablosu; `collection_id`, `user_id`, title, description, image_url, latitude, longitude, metadata (JSONB).
- **Profil:** `getCurrentUserProfile()` — `profiles` tablosu. `getMyPinsCount()`, `getMyCollectionsCount()` sayılar için.

**Migration’lar:**  
- `profiles.sql`: profiles tablosu, auth trigger ile yeni kullanıcıda satır.  
- `002_collections_and_pins.sql`: collections ve pins tabloları, RLS (sadece kendi satırları).

**Modeller:** `CollectionModel` (id, userId, name, description, createdAt), `PinModel` (id, collectionId, userId, title, description, imageUrl, latitude, longitude, metadata, createdAt); `PinModel.forInsert(...)` insert için.

---

## 8. Library (My Journey) Ekranı

**Dosya:** `lib/screens/library_view.dart`

- Üstte **profil başlığı** (@traveler, “Edit Profile” butonu), ayarlar ikonu.
- Koleksiyonlar **Supabase**’ten: `getCollections()` → UI modeli `Collection` (library_models: id, name, pinCount, coverImageUrl, isPrivate). Pin sayısı şu an DB’de değil; Library tarafında 0/default.
- **Boş durum:** Koleksiyon yoksa “Your journey starts here.” + **“Create journey”** butonu → `CreateCollectionSheet` açılır.
- **Dolu durum:** Grid’de ilk hücre “New Journey” (create), diğerleri `_CollectionCard`; karta tıklanınca `CollectionDetailView(collection)` açılır.
- Collection oluşturma: paylaşılan **CreateCollectionSheet** (`lib/screens/create_collection_sheet.dart`) → `SupabaseService().createCollection(name)` → dönen `CollectionModel` → `Collection`’a map edilip listeye eklenir.

---

## 9. Collection Detail

**Dosya:** `lib/screens/collection_detail_view.dart`

- **Veri:** Pin’ler artık **Supabase**’ten: `SupabaseService().getPins(collection.id)` → `PinModel` listesi → `SavedPin` (library_models) formatına çevrilir; harita ve liste bu listeyi kullanır.
- Üstte küçük harita (pin marker’ları), altında pin sayısı ve “Private/Public”, sonra pin kartları (`_PinPostCard`).

---

## 10. Profile Ekranı (ProfileView)

**Dosya:** `lib/screens/profile_view.dart`

- **Not:** Bu ekran şu an **main navigasyon’da kullanılmıyor**; sadece Library (index 1) gösteriliyor. ProfileView ayrı bir “tam profil” ekranı olarak mevcut.
- İçerik: Supabase’ten profil + pin sayısı + koleksiyon sayısı. Sekmeler: **My Pins** (tüm pin’ler grid), **Saved** (placeholder), **Collections** (koleksiyon grid’i + “New Journey” ile oluşturma). Collection’a tıklanınca yine `CollectionDetailView` açılır.

Yani koleksiyon oluşturma hem Library boş ekrandan hem Library grid’den hem de (kodda hazır olan) ProfileView Collections sekmesinden yapılabilecek şekilde tasarlanmış; ana kullanıcı akışı Library üzerinden.

---

## 11. Auth

**Dosya:** `lib/screens/auth_view.dart`, `lib/services/auth_service.dart`

- **AuthService:** Singleton; `signUp(email, password, username, fullName)`, `signIn(email, password)`, `signOut()` — hepsi Supabase Auth.
- AuthView: Sign In / Sign Up formu; başarıda `onAuthenticated()` ile MainShell’e geçilir.
- Yeni kullanıcı: `profiles` tablosuna trigger ile satır eklenir (profiles.sql).

---

## 12. State ve Veri Akışı Özeti

| Veri | Nerede tutulur | Nerede kullanılır |
|------|----------------|--------------------|
| Oturum | Supabase Auth | main.dart _AppHome, tüm Supabase çağrıları |
| Koleksiyonlar | Supabase `collections` | LibraryView, ProfileView, MapScreen (filtre chip’leri), CreateCollectionSheet |
| Pin’ler (kalıcı) | Supabase `pins` | MapScreen (marker’lar), CollectionDetailView, ProfileView My Pins |
| Kullanıcı pin’leri (session) | SavedPlacesProvider (bellek) | MapScreen userPinnedLocations, confirm preview’da ekleme |
| Preview (AI sonucu) | MainShell state | MapScreen preview marker + “Found it!” kartı |
| Onboarding tamamlandı mı | shared_preferences | main.dart _AppHome |
| Ayarlar (public profile vb.) | SettingsProvider | settings_view |

---

## 13. Önemli Dosya Konumları

```
lib/
  main.dart                    # Giriş, Supabase init, Provider, routing
  screens/
    landing_view.dart
    onboarding_view.dart
    auth_view.dart
    main_shell.dart            # Map | AI | Library, preview state, AI overlay
    map_screen.dart            # Harita, marker’lar, Save to collection
    library_view.dart          # Koleksiyon grid, Create journey, CollectionDetail açılışı
    profile_view.dart          # My Pins / Saved / Collections (navigasyonda kullanılmıyor)
    collection_detail_view.dart # Koleksiyon detayı, Supabase’ten pin listesi
    create_collection_sheet.dart # Paylaşılan “New Journey” bottom sheet
    settings_view.dart
    edit_profile_view.dart
  services/
    supabase_service.dart      # Collections, Pins, Profile, counts
    ai_service.dart            # Gemini analiz + geocoding
    auth_service.dart
  models/
    collection_model.dart      # Supabase collection
    pin_model.dart             # Supabase pin
    library_models.dart       # Collection, SavedPin (UI)
    mock_location.dart         # Harita/pin konumu
    profile_data.dart          # UserProfile
    saved_place.dart           # SavedPlace (location + AnalyzedSpot + imageBytes)
  providers/
    saved_places_provider.dart
    settings_provider.dart
  widgets/
    analysis_overlay.dart      # AI analiz ekranı
    map_pin.dart
supabase/migrations/
  profiles.sql
  002_collections_and_pins.sql
```

---

## 14. Kısa Özet (Başka AI’a tek paragraf)

PinTok, Flutter + Supabase + Gemini kullanan bir seyahat pin uygulamasıdır. Kullanıcı önce Landing → Onboarding → Auth ile giriş yapar. Ana ekran (MainShell) iki sekmedir: Map ve Library (alt bar’da Map | AI butonu | Library). AI butonu fotoğraf seçtirir; Gemini ile yer bilgisi (AnalyzedSpot) ve geocoding ile konum (MockLocation) üretilir; sonuç haritada “preview” pin olarak gösterilir. Kullanıcı “Add to map” ile bir koleksiyon seçer; pin Supabase’e kaydedilir ve SavedPlacesProvider’a eklenir. Haritada kullanıcı pin’leri + Supabase’ten gelen koleksiyon pin’leri gösterilir; koleksiyon filtresi chip’lerle yapılır. Library’de koleksiyonlar grid’de listelenir; boş durumda “Create journey” ile CreateCollectionSheet açılır; koleksiyon Supabase’te oluşturulur. Collection detail’de pin’ler Supabase’ten getPins(collectionId) ile çekilir. ProfileView (My Pins / Saved / Collections) kodu var ama ana navigasyonda kullanılmıyor; ana akış Library üzerinden. Tüm kalıcı veri Supabase’te (profiles, collections, pins); RLS ile kullanıcı sadece kendi verisini görür/düzenler.

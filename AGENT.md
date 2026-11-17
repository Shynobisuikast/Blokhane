# AGENT.md - Blok Bulmacası (Godot 4 / GDScript)

Bu dosya hem proje talimatıdır hem de her fazda uyulacak kalite kurallarıdır.
Her oturumun başında bu dosyayı ve PLAN.md'yi oku. AKTİF fazı PLAN.md'den bul.

## 1. Rol ve dil

- Godot 4.x ve GDScript uzmanısın. Kullanıcı Türkçe konuşur.
- Kod yorumları Türkçe, değişken/fonksiyon/sınıf adları İngilizce.
- Kısa ve net yaz. Giriş ve sonuç paragrafı yazma.

## 2. Oyun tanımı (tasarımdan çıkarıldı, değiştirme)

Tür: sürükle-bırak blok bulmacası. Tetris DEĞİL: parça düşmez, döndürme yoktur.

- Tahta 8x8 ızgara. Hücre 48 px, hücreler arası boşluk 4 px. Ekran 480x860 dikey.
- Alt tepsi: her turda 3 rastgele parça. Oyuncu bir parçayı tahtaya sürükleyip bırakır.
- Sürüklerken geçerli yerde kesikli sarı çizgili önizleme gösterilir.
- Geçersiz yere bırakılırsa parça tepsideki yerine döner.
- Dolu satır veya sütun temizlenir. Üç parça da kullanılınca yeni üçlü gelir.
- Tepsideki hiçbir parça tahtaya sığmıyorsa oyun biter.
- Üstte duraklat düğmesi, skor ve en yüksek skor bulunur.
- Çelişki olursa tasarım SVG'leri kazanır. Çelişkiyi bildir, varsayma.

## 3. Teknik kurallar

- Godot 4 API: `@export`, `@onready`, `await`, `signal.connect()`, `PackedScene`.
- Mantık ve görünüm ayrı olsun: `BoardModel` (saf veri, Node değil) ve görsel katman ayrı dosyada.
- Sihirli sayı yok. Sabitler `Config.gd` içinde (CELL_SIZE, GAP, BOARD_SIZE, renkler).
- Parça şekilleri veri olarak tutulur (`Vector2i` dizisi), if/else zinciriyle değil.
- Sinyalleri doğrudan çağrı yerine tercih et (örn. `lines_cleared`, `game_over`, `score_changed`).
- Her dosya tek sorumluluk taşır. 200 satırı aşan script'i böl.
- Tip belirt: `var score: int = 0`, `func place(...) -> bool`.
- Girdi `_unhandled_input` veya Control node sinyalleriyle, hem fare hem dokunmatik çalışmalı.

## 4. Hedef yapı

res://
scenes/ Main.tscn, Game.tscn, Menu.tscn, GameOver.tscn
scripts/ Config.gd, Pieces.gd, BoardModel.gd, BoardView.gd, Tray.gd,
DraggablePiece.gd, Game.gd, SaveData.gd, Main.gd
assets/ svg/ (menu, gameover, dark, light)

## 5. Çalışma biçimi (her cevapta)

1. Yalnızca AKTİF fazı yap. Başka faza taşma.
2. Belirsizlik varsa tek bir kısa soru sor, sonra yaz.
3. Yalnızca değişen dosyaları ver. Dosya yolu ilk satır yorumu olsun: `# scripts/BoardModel.gd`
4. Önce kod, sonra en fazla 3 maddelik açıklama.
5. Cevabın sonunda şunları ver:
   - "Test adımları": kullanıcının Godot'ta yapacağı 3-5 somut adım
   - "Beklenen sonuç": ne görmeli
   - "Sıradaki adım": tek cümle
6. Hata ayıklamada önce hata mesajını ve ilgili en küçük kodu iste. Projeyi baştan yazma.
7. Yeni eklenti, plugin veya dış araç önerme. Gerekirse önce tek cümleyle gerekçelendir.

## 6. Faz kapıları (Definition of Done)

Bir faz, aşağıdaki liste geçilmeden "bitti" sayılmaz. Kullanıcıdan onay almadan sonraki faza geçme.

- [ ] Proje hatasız açılıyor, Output panelinde hata veya uyarı yok.
- [ ] Fazın kabul kriteri (PLAN.md) elle test edildi.
- [ ] Önceki fazların davranışı bozulmadı (kısa regresyon testi).
- [ ] Yeni mantık için en az bir basit doğrulama var (aşağıya bak).
- [ ] Sihirli sayı veya kopyala-yapıştır kod kalmadı.
- [ ] PLAN.md'deki faz işaretlendi, gidişat günlüğüne satır eklendi.

Doğrulama için GUT gibi eklenti kurma. Bunun yerine `BoardModel` için `tests/smoke_test.gd` içinde
`assert()` kullanan küçük bir betik yaz ve fazın sonunda çalıştır.

## 7. Faza özel kurallar

### Faz 0 - Kurulum

- Pencere 480x860, `stretch mode = canvas_items`, `aspect = keep`, dikey yönlendirme.
- Arka plan #0D1A38. Config.gd ve renk sabitleri burada oluşturulur.

### Faz 1 - Tahta modeli (görsel yok)

- `BoardModel`: 8x8 `Array`, `can_place(piece, origin)`, `place(piece, origin)`, `find_full_lines()`, `clear_lines()`.
- Tüm mantık Node olmadan çalışmalı. smoke_test ile en az şunları doğrula: sığma, çakışma, taşma, satır temizleme, sütun temizleme, aynı anda satır+sütun.

### Faz 2 - Tahta çizimi

- BoardView modeli çizer, modeli değiştirmez. Hücre 48 px, boşluk 4 px, köşe yuvarlak (rx 12 gibi), tasarımdaki iç gölge hissi.
- Boş hücre #22407F, dolu hücre parçanın rengi.

### Faz 3 - Parça seti ve tepsi

- 3 parçalık üretim. En az 15-20 şekil (tek hücre, çizgiler, kare, L, T, Z varyantları).
- Adil üretim: üç parçadan en az biri mevcut tahtaya sığmalı. Bu kural yoksa oyun haksız biter.

### Faz 4 - Sürükle-bırak

- Parçayı sürüklerken parmağın biraz üstünde göster (parmak parçayı kapatmasın).
- Bırakınca tahta hücresine yapış (snap). Geçersizse tweenle geri dön.
- Fare ve dokunmatik aynı kodla çalışsın. Aynı anda tek parça sürüklenir.

### Faz 5 - Önizleme

- Geçerli konumda kesikli sarı çizgili hücreler, tasarımdaki gibi. Geçersizse gösterme.
- Satır/sütun tamamlanacaksa o hücreleri vurgula (kullanıcıya ödül hissi verir).

### Faz 6 - Temizleme ve skor

- Skor: yerleştirilen hücre sayısı + temizlenen çizgi bonusu. Aynı anda birden çok çizgi katlanarak artar.
- Combo: art arda temizleyen turlarda çarpan. Formülü Config.gd'de tut.
- Temizleme animasyonu (kısa tween), animasyon sırasında girdi kilitli.

### Faz 7 - Oyun sonu

- Yeni üçlü geldikten sonra hiçbir parça sığmıyorsa oyun biter.
- GameOver ekranı skor ve en yüksek skoru gösterir, "Tekrar oyna" çalışır.
- En yüksek skor `user://save.cfg` içine `ConfigFile` ile kaydedilir.

### Faz 8 - Ana menü ve duraklat

- menu.svg referansı: logo, oyna ve ikinci düğme.
- Duraklat: `get_tree().paused`, devam ve menüye dön.

### Faz 9 - Parlatma (ürün kalitesi)

- Parça bırakma, temizleme ve oyun sonu için kısa tweenler (ölçek, solma).
- Dokunma hedefleri en az 48 px. Düğmelerde basılı durumu.
- Kullanılmayan kod ve konsol yazdırmaları temizlenir.
- 60 FPS: `_process` içinde her karede tüm tahtayı yeniden çizme. Yalnızca değişince çiz.

### Faz 10 - Tema

- dark.svg ve light.svg paletleri `Config.gd` içinde iki sözlük olarak tutulur.
- Renk tema üzerinden okunur, koda gömülmez. Seçim kaydedilir.

### Faz 11 - Ses (opsiyonel)

- Bırakma, temizleme, oyun sonu sesleri. Ses aç/kapa ayarı kaydedilir.

## 8. Yapma

- Düşen parça, döndürme, Timer ile otomatik hareket ekleme.
- Fazı atlayıp "bonus" özellik ekleme (online skor, reklam, satın alma).
- Çalışan kodu "iyileştirme" amacıyla baştan yazma. Önce neden gerektiğini söyle.
- Test etmediğin kodu "çalışır" diye sunma. Emin değilsen bunu belirt.

## 9. Renk paleti (tasarımdan)

Koyu tema: arka plan #0D1A38, panel #14264F, boş hücre #22407F, mavi #3F6BFF,
turkuaz #1FB8A8, sarı #F2B632, kırmızı #E8553E, yeşil #3FA66B,
metin #F2EEE4, ikincil metin #9FB0D4.
Açık tema: arka plan #E8EEF0, panel #D3DEE2, boş hücre #C2D1D7, mavi #2F6FED,
turkuaz #0F8B8D, sarı #E0A100, kırmızı #E2563B, yeşil #4F9D5D, metin #14262C, ikincil metin #4F6A72.
